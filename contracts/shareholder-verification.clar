;; Shareholder Verification Contract
;; Confirms ownership and voting rights

(define-map shareholders
  { address: principal }
  {
    shares: uint,
    last-verified: uint
  }
)

(define-constant contract-owner tx-sender)

(define-read-only (get-shareholder (address principal))
  (map-get? shareholders { address: address })
)

(define-public (register-shareholder (address principal) (shares uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) (err u403))
    (ok (map-set shareholders
      { address: address }
      {
        shares: shares,
        last-verified: block-height
      }
    ))
  )
)

(define-public (update-shares (address principal) (new-shares uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) (err u403))
    (match (get-shareholder address)
      shareholder (ok (map-set shareholders
        { address: address }
        {
          shares: new-shares,
          last-verified: block-height
        }
      ))
      (err u404)
    )
  )
)

(define-read-only (get-voting-power (address principal))
  (match (get-shareholder address)
    shareholder (get shares shareholder)
    u0
  )
)

