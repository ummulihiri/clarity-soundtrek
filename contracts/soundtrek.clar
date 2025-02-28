;; Constants
(define-constant ERR-NOT-FOUND (err u100))
(define-constant ERR-UNAUTHORIZED (err u101))
(define-constant ERR-INVALID-INPUT (err u102))

;; Data structures
(define-map entries
  { entry-id: uint }
  {
    owner: principal,
    title: (string-utf8 64),
    timestamp: uint,
    latitude: int,
    longitude: int,
    audio-hash: (string-ascii 64),
    is-public: bool,
    likes: uint
  }
)

(define-map user-likes
  { user: principal, entry-id: uint }
  { liked: bool }
)

;; Storage
(define-data-var next-entry-id uint u1)

;; Create new audio diary entry
(define-public (create-entry
    (title (string-utf8 64))
    (timestamp uint)
    (location {latitude: int, longitude: int})
    (audio-hash (string-ascii 64))
    (is-public bool))
  (let
    ((entry-id (var-get next-entry-id)))
    (map-set entries
      {entry-id: entry-id}
      {
        owner: tx-sender,
        title: title,
        timestamp: timestamp,
        latitude: (get latitude location),
        longitude: (get longitude location),
        audio-hash: audio-hash,
        is-public: is-public,
        likes: u0
      }
    )
    (var-set next-entry-id (+ entry-id u1))
    (ok entry-id)
  )
)

;; Like an entry
(define-public (like-entry (entry-id uint))
  (let
    ((entry (unwrap! (map-get? entries {entry-id: entry-id}) ERR-NOT-FOUND))
     (user-like (default-to {liked: false} 
       (map-get? user-likes {user: tx-sender, entry-id: entry-id}))))
    (asserts! (get is-public entry) ERR-UNAUTHORIZED)
    (if (get liked user-like)
      (ok false)
      (begin
        (map-set entries 
          {entry-id: entry-id}
          (merge entry {likes: (+ (get likes entry) u1)}))
        (map-set user-likes
          {user: tx-sender, entry-id: entry-id}
          {liked: true})
        (ok true)
      )
    )
  )
)

;; Get entry by ID
(define-read-only (get-entry (entry-id uint))
  (let ((entry (unwrap! (map-get? entries {entry-id: entry-id}) ERR-NOT-FOUND)))
    (if (or (get is-public entry) (is-eq tx-sender (get owner entry)))
      (ok entry)
      ERR-UNAUTHORIZED
    )
  )
)

;; Get entries by location (simplified)
(define-read-only (get-entries-by-location 
    (location {latitude: int, longitude: int})
    (radius uint))
  (ok true) ;; Actual implementation would require off-chain indexing
)
