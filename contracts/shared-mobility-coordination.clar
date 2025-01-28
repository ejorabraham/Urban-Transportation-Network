;; Shared Mobility Coordination Contract

(define-map ride-requests
  { request-id: uint }
  {
    requester: principal,
    pickup-location: (string-ascii 100),
    dropoff-location: (string-ascii 100),
    requested-at: uint,
    status: (string-ascii 20)
  }
)

(define-map ride-offers
  { offer-id: uint }
  {
    driver: principal,
    vehicle-type: (string-ascii 50),
    available-seats: uint,
    current-location: (string-ascii 100),
    status: (string-ascii 20)
  }
)

(define-data-var request-id-nonce uint u0)
(define-data-var offer-id-nonce uint u0)

(define-public (create-ride-request
  (pickup-location (string-ascii 100))
  (dropoff-location (string-ascii 100))
)
  (let
    ((new-request-id (+ (var-get request-id-nonce) u1)))
    (map-set ride-requests
      { request-id: new-request-id }
      {
        requester: tx-sender,
        pickup-location: pickup-location,
        dropoff-location: dropoff-location,
        requested-at: block-height,
        status: "pending"
      }
    )
    (var-set request-id-nonce new-request-id)
    (ok new-request-id)
  )
)

(define-public (create-ride-offer
  (vehicle-type (string-ascii 50))
  (available-seats uint)
  (current-location (string-ascii 100))
)
  (let
    ((new-offer-id (+ (var-get offer-id-nonce) u1)))
    (map-set ride-offers
      { offer-id: new-offer-id }
      {
        driver: tx-sender,
        vehicle-type: vehicle-type,
        available-seats: available-seats,
        current-location: current-location,
        status: "available"
      }
    )
    (var-set offer-id-nonce new-offer-id)
    (ok new-offer-id)
  )
)

(define-public (accept-ride-request (request-id uint) (offer-id uint))
  (let
    ((request (unwrap! (map-get? ride-requests { request-id: request-id }) (err u404)))
     (offer (unwrap! (map-get? ride-offers { offer-id: offer-id }) (err u404))))
    (asserts! (is-eq (get driver offer) tx-sender) (err u403))
    (asserts! (is-eq (get status offer) "available") (err u401))
    (asserts! (is-eq (get status request) "pending") (err u402))
    (map-set ride-requests
      { request-id: request-id }
      (merge request { status: "accepted" })
    )
    (map-set ride-offers
      { offer-id: offer-id }
      (merge offer { status: "en-route", available-seats: (- (get available-seats offer) u1) })
    )
    (ok true)
  )
)

(define-read-only (get-ride-request (request-id uint))
  (map-get? ride-requests { request-id: request-id })
)

(define-read-only (get-ride-offer (offer-id uint))
  (map-get? ride-offers { offer-id: offer-id })
)

