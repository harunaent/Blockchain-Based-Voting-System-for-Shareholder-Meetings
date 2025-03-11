;; Proxy Assignment Contract
;; Allows shareholders to delegate voting rights

(define-map proxy-assignments
  { shareholder: principal }
  { proxy: principal }
)

(define-read-only (get-proxy (shareholder principal))
  (map-get? proxy-assignments { shareholder: shareholder })
)

(define-public (assign-proxy (proxy principal))
  (ok (map-set proxy-assignments
    { shareholder: tx-sender }
    { proxy: proxy }
  ))
)

(define-public (revoke-proxy)
  (ok (map-delete proxy-assignments { shareholder: tx-sender }))
)

(define-read-only (get-effective-voter (shareholder principal))
  (match (get-proxy shareholder)
    proxy-info (get proxy proxy-info)
    shareholder
  )
)

