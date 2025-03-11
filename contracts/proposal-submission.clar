;; Proposal Submission Contract
;; Manages the creation and modification of proposals

(define-map proposals
  { proposal-id: uint }
  {
    title: (string-ascii 100),
    description: (string-ascii 500),
    proposer: principal,
    start-block: uint,
    end-block: uint,
    status: (string-ascii 20)
  }
)

(define-data-var proposal-nonce uint u0)

(define-constant contract-owner tx-sender)

(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals { proposal-id: proposal-id })
)

(define-public (submit-proposal (title (string-ascii 100)) (description (string-ascii 500)) (blocks uint))
  (let
    (
      (new-proposal-id (+ (var-get proposal-nonce) u1))
    )
    (asserts! (> blocks u0) (err u400))
    (var-set proposal-nonce new-proposal-id)
    (ok (map-set proposals
      { proposal-id: new-proposal-id }
      {
        title: title,
        description: description,
        proposer: tx-sender,
        start-block: block-height,
        end-block: (+ block-height blocks),
        status: "active"
      }
    ))
  )
)

(define-public (close-proposal (proposal-id uint))
  (let
    (
      (proposal (unwrap! (get-proposal proposal-id) (err u404)))
    )
    (asserts! (is-eq tx-sender contract-owner) (err u403))
    (asserts! (>= block-height (get end-block proposal)) (err u400))
    (ok (map-set proposals
      { proposal-id: proposal-id }
      (merge proposal { status: "closed" })
    ))
  )
)

