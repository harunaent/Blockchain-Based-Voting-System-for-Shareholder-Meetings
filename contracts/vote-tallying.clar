;; Vote Tallying Contract
;; Securely counts votes and reports results

(define-map proposals
  { proposal-id: uint }
  {
    end-block: uint,
    status: (string-ascii 10)
  }
)

(define-map votes
  { proposal-id: uint, voter: principal }
  { vote: (string-ascii 10), weight: uint }
)

(define-map vote-tallies
  { proposal-id: uint }
  {
    for: uint,
    against: uint,
    abstain: uint
  }
)

(define-data-var proposal-nonce uint u0)

(define-constant contract-owner tx-sender)

(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals { proposal-id: proposal-id })
)

(define-read-only (get-vote (proposal-id uint) (voter principal))
  (map-get? votes { proposal-id: proposal-id, voter: voter })
)

(define-read-only (get-vote-tally (proposal-id uint))
  (default-to
    { for: u0, against: u0, abstain: u0 }
    (map-get? vote-tallies { proposal-id: proposal-id })
  )
)

(define-public (create-proposal (blocks uint))
  (let
    (
      (new-proposal-id (+ (var-get proposal-nonce) u1))
    )
    (asserts! (> blocks u0) (err u400))
    (var-set proposal-nonce new-proposal-id)
    (ok (map-set proposals
      { proposal-id: new-proposal-id }
      {
        end-block: (+ block-height blocks),
        status: "active"
      }
    ))
  )
)

(define-public (cast-vote (proposal-id uint) (vote (string-ascii 10)) (weight uint))
  (let
    (
      (proposal (unwrap! (get-proposal proposal-id) (err u404)))
      (current-tally (get-vote-tally proposal-id))
    )
    (asserts! (< block-height (get end-block proposal)) (err u400))
    (asserts! (is-eq (get status proposal) "active") (err u401))
    (asserts! (or (is-eq vote "for") (is-eq vote "against") (is-eq vote "abstain")) (err u402))
    (map-set votes
      { proposal-id: proposal-id, voter: tx-sender }
      { vote: vote, weight: weight }
    )
    (map-set vote-tallies
      { proposal-id: proposal-id }
      (merge current-tally
        {
          for: (if (is-eq vote "for") (+ (get for current-tally) weight) (get for current-tally)),
          against: (if (is-eq vote "against") (+ (get against current-tally) weight) (get against current-tally)),
          abstain: (if (is-eq vote "abstain") (+ (get abstain current-tally) weight) (get abstain current-tally))
        }
      )
    )
    (ok true)
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

