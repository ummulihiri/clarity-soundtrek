;; SoundTrek: Decentralized Audio Diary Platform
;; Enhanced version with additional features and security measures

;; Constants
(define-constant ERR-NOT-FOUND (err u100))
(define-constant ERR-UNAUTHORIZED (err u101))
(define-constant ERR-INVALID-INPUT (err u102))
(define-constant ERR-ALREADY-EXISTS (err u103))

;; Traits
(define-trait soundtrek-trait
  (
    (create-entry (string-utf8 64) uint {latitude: int, longitude: int} (string-ascii 64) bool) (response uint uint))
    (update-entry (uint) (string-utf8 64) (string-ascii 64) bool (response bool uint))
    (delete-entry (uint) (response bool uint))
    (like-entry (uint) (response bool uint))
  )
)

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

(define-map comments
  { entry-id: uint, comment-id: uint }
  {
    author: principal,
    content: (string-utf8 280),
    timestamp: uint
  }
)

;; Storage
(define-data-var next-entry-id uint u1)
(define-data-var next-comment-id uint u1)

;; Helper functions
(define-private (validate-coordinates (lat int) (lon int))
  (and
    (>= lat (* -90 u1000000))
    (<= lat (* 90 u1000000))
    (>= lon (* -180 u1000000))
    (<= lon (* 180 u1000000))
  )
)

;; Create new audio diary entry
(define-public (create-entry
    (title (string-utf8 64))
    (timestamp uint)
    (location {latitude: int, longitude: int})
    (audio-hash (string-ascii 64))
    (is-public bool))
  (let
    ((entry-id (var-get next-entry-id))
     (lat (get latitude location))
     (lon (get longitude location)))
    (asserts! (validate-coordinates lat lon) ERR-INVALID-INPUT)
    (map-set entries
      {entry-id: entry-id}
      {
        owner: tx-sender,
        title: title,
        timestamp: timestamp,
        latitude: lat,
        longitude: lon,
        audio-hash: audio-hash,
        is-public: is-public,
        likes: u0
      }
    )
    (var-set next-entry-id (+ entry-id u1))
    (ok entry-id)
  )
)

;; Update existing entry
(define-public (update-entry 
    (entry-id uint)
    (new-title (string-utf8 64))
    (new-audio-hash (string-ascii 64))
    (new-is-public bool))
  (let ((entry (unwrap! (map-get? entries {entry-id: entry-id}) ERR-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get owner entry)) ERR-UNAUTHORIZED)
    (map-set entries
      {entry-id: entry-id}
      (merge entry {
        title: new-title,
        audio-hash: new-audio-hash,
        is-public: new-is-public
      })
    )
    (ok true)
  )
)

;; Delete entry
(define-public (delete-entry (entry-id uint))
  (let ((entry (unwrap! (map-get? entries {entry-id: entry-id}) ERR-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get owner entry)) ERR-UNAUTHORIZED)
    (map-delete entries {entry-id: entry-id})
    (ok true)
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

;; Add comment
(define-public (add-comment (entry-id uint) (content (string-utf8 280)))
  (let 
    ((entry (unwrap! (map-get? entries {entry-id: entry-id}) ERR-NOT-FOUND))
     (comment-id (var-get next-comment-id)))
    (asserts! (get is-public entry) ERR-UNAUTHORIZED)
    (map-set comments
      {entry-id: entry-id, comment-id: comment-id}
      {
        author: tx-sender,
        content: content,
        timestamp: block-height
      }
    )
    (var-set next-comment-id (+ comment-id u1))
    (ok comment-id)
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

;; Get entries by location with basic proximity check
(define-read-only (get-entries-by-location 
    (location {latitude: int, longitude: int})
    (radius uint))
  (let ((lat (get latitude location))
        (lon (get longitude location)))
    (asserts! (validate-coordinates lat lon) ERR-INVALID-INPUT)
    (ok true) ;; Enhanced implementation would require off-chain indexing
  )
)
