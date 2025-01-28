;; Eco-Commute Incentives Contract

(define-fungible-token eco-token)

(define-non-fungible-token eco-achievement uint)

(define-map user-eco-score
  { user: principal }
  { score: uint }
)

(define-map achievement-info
  { achievement-id: uint }
  {
    title: (string-ascii 100),
    description: (string-utf8 500),
    threshold: uint
  }
)

(define-data-var achievement-id-nonce uint u0)

(define-constant AUTHORIZED_VALIDATORS
  (list
    'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM
    'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG
  )
)

(define-read-only (is-authorized-validator (address principal))
  (is-some (index-of AUTHORIZED_VALIDATORS address))
)

(define-public (record-eco-commute (user principal) (eco-points uint))
  (begin
    (asserts! (is-authorized-validator tx-sender) (err u403))
    (let
      ((current-score (default-to { score: u0 } (map-get? user-eco-score { user: user }))))
      (map-set user-eco-score
        { user: user }
        { score: (+ (get score current-score) eco-points) }
      )
      (try! (ft-mint? eco-token eco-points user))
      (ok true)
    )
  )
)

(define-public (create-achievement
  (title (string-ascii 100))
  (description (string-utf8 500))
  (threshold uint)
)
  (let
    ((new-achievement-id (+ (var-get achievement-id-nonce) u1)))
    (asserts! (is-authorized-validator tx-sender) (err u403))
    (map-set achievement-info
      { achievement-id: new-achievement-id }
      {
        title: title,
        description: description,
        threshold: threshold
      }
    )
    (var-set achievement-id-nonce new-achievement-id)
    (ok new-achievement-id)
  )
)

(define-public (award-achievement (user principal) (achievement-id uint))
  (let
    ((achievement (unwrap! (map-get? achievement-info { achievement-id: achievement-id }) (err u404)))
     (user-score (default-to { score: u0 } (map-get? user-eco-score { user: user }))))
    (asserts! (is-authorized-validator tx-sender) (err u403))
    (asserts! (>= (get score user-score) (get threshold achievement)) (err u401))
    (try! (nft-mint? eco-achievement achievement-id user))
    (ok true)
  )
)

(define-read-only (get-user-eco-score (user principal))
  (default-to { score: u0 } (map-get? user-eco-score { user: user }))
)

(define-read-only (get-achievement-info (achievement-id uint))
  (map-get? achievement-info { achievement-id: achievement-id })
)

