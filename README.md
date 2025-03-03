# SoundTrek
A decentralized application for creating audio diaries and location-based soundscapes on the Stacks blockchain.

## Features
- Create audio diary entries with location data
- Share soundscapes publicly or keep them private 
- Discover soundscapes by location
- Like and comment on public soundscapes
- Earn rewards for popular contributions

## Setup and Installation
1. Clone the repository
2. Install Clarinet
3. Run `clarinet check` to verify contracts
4. Run `clarinet test` to execute test suite

## Usage Examples
```clarity
;; Create a new audio diary entry
(contract-call? .soundtrek create-entry "My Beach Recording" 
  u123456789 ;; timestamp
  {latitude: 34.052235, longitude: -118.243683} ;; location
  "ipfs://Qm..." ;; audio file hash
  true) ;; public flag

;; Discover soundscapes in an area
(contract-call? .soundtrek get-entries-by-location
  {latitude: 34.052235, longitude: -118.243683}
  u10000) ;; radius in meters

;; Like an entry
(contract-call? .soundtrek like-entry u1)
```

## Dependencies
- Clarity language
- Clarinet for testing/deployment
- IPFS for audio storage
