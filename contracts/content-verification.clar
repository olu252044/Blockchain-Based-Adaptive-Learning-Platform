;; content-verification.clar
;; Contract to verify educational content

(define-data-var admin principal tx-sender)

;; Map of verified educational content
(define-map verified-content
  { content-id: (string-ascii 64) }
  {
    provider: principal,
    content-hash: (buff 32),
    verification-time: uint,
    is-verified: bool
  }
)

;; Public function to submit content for verification
(define-public (submit-content (content-id (string-ascii 64)) (content-hash (buff 32)))
  (let
    ((provider tx-sender)
     (current-time (unwrap-panic (get-block-info? time (- block-height u1)))))
    (if (is-some (map-get? verified-content { content-id: content-id }))
      (err u1) ;; Content ID already exists
      (begin
        (map-set verified-content
          { content-id: content-id }
          {
            provider: provider,
            content-hash: content-hash,
            verification-time: current-time,
            is-verified: false
          }
        )
        (ok true)
      )
    )
  )
)

;; Admin function to verify content
(define-public (verify-content (content-id (string-ascii 64)))
  (let
    ((current-time (unwrap-panic (get-block-info? time (- block-height u1)))))
    (begin
      (asserts! (is-eq tx-sender (var-get admin)) (err u403))
      (match (map-get? verified-content { content-id: content-id })
        content-data (begin
          (map-set verified-content
            { content-id: content-id }
            (merge content-data { is-verified: true, verification-time: current-time })
          )
          (ok true)
        )
        (err u2) ;; Content not found
      )
    )
  )
)

;; Read-only function to check if content is verified
(define-read-only (is-content-verified (content-id (string-ascii 64)))
  (match (map-get? verified-content { content-id: content-id })
    content-data (get is-verified content-data)
    false
  )
)

;; Read-only function to get content details
(define-read-only (get-content-details (content-id (string-ascii 64)))
  (map-get? verified-content { content-id: content-id })
)

;; Administrative function to change admin
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
