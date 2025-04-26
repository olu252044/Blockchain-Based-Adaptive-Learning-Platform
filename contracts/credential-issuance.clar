;; credential-issuance.clar
;; Contract to issue and verify credentials based on completed achievements

(define-data-var admin principal tx-sender)

;; Map of credential types
(define-map credential-types
  { credential-id: (string-ascii 64) }
  {
    name: (string-utf8 64),
    description: (string-utf8 256),
    issuer: principal,
    creation-time: uint,
    requirements: (list 10 (string-ascii 64)), ;; List of required assessment IDs
    is-active: bool
  }
)

;; Map of issued credentials
(define-map issued-credentials
  { student-id: principal, credential-id: (string-ascii 64) }
  {
    issuance-time: uint,
    expiration-time: (optional uint),
    verification-hash: (buff 32),
    revoked: bool
  }
)

;; Public function to create a new credential type (admin only)
(define-public (create-credential-type
  (credential-id (string-ascii 64))
  (name (string-utf8 64))
  (description (string-utf8 256))
  (requirements (list 10 (string-ascii 64))))
  (let
    ((issuer tx-sender)
     (current-time (unwrap-panic (get-block-info? time (- block-height u1)))))
    (begin
      (asserts! (is-eq issuer (var-get admin)) (err u403))
      (if (is-some (map-get? credential-types { credential-id: credential-id }))
        (err u1) ;; Credential ID already exists
        (begin
          (map-set credential-types
            { credential-id: credential-id }
            {
              name: name,
              description: description,
              issuer: issuer,
              creation-time: current-time,
              requirements: requirements,
              is-active: true
            }
          )
          (ok true)
        )
      )
    )
  )
)

;; Public function to issue a credential
(define-public (issue-credential
  (student-id principal)
  (credential-id (string-ascii 64))
  (verification-hash (buff 32))
  (expiration-time (optional uint)))
  (let
    ((issuer tx-sender)
     (current-time (unwrap-panic (get-block-info? time (- block-height u1)))))
    (begin
      (match (map-get? credential-types { credential-id: credential-id })
        credential-type (begin
          (asserts! (is-eq issuer (get issuer credential-type)) (err u403))
          (asserts! (get is-active credential-type) (err u4))
          (map-set issued-credentials
            { student-id: student-id, credential-id: credential-id }
            {
              issuance-time: current-time,
              expiration-time: expiration-time,
              verification-hash: verification-hash,
              revoked: false
            }
          )
          (ok true)
        )
        (err u2) ;; Credential type not found
      )
    )
  )
)

;; Public function to revoke a credential
(define-public (revoke-credential (student-id principal) (credential-id (string-ascii 64)))
  (begin
    (match (map-get? credential-types { credential-id: credential-id })
      credential-type (begin
        (asserts! (is-eq tx-sender (get issuer credential-type)) (err u403))
        (match (map-get? issued-credentials { student-id: student-id, credential-id: credential-id })
          credential-data (begin
            (map-set issued-credentials
              { student-id: student-id, credential-id: credential-id }
              (merge credential-data { revoked: true })
            )
            (ok true)
          )
          (err u3) ;; Credential not issued
        )
      )
      (err u2) ;; Credential type not found
    )
  )
)

;; Read-only function to verify a credential
(define-read-only (verify-credential (student-id principal) (credential-id (string-ascii 64)))
  (match (map-get? issued-credentials { student-id: student-id, credential-id: credential-id })
    credential-data (begin
      (match (get expiration-time credential-data)
        expiry-time (and
          (not (get revoked credential-data))
          (> expiry-time (unwrap-panic (get-block-info? time (- block-height u1))))
        )
        (not (get revoked credential-data)) ;; No expiration
      )
    )
    false
  )
)

;; Read-only function to get credential details
(define-read-only (get-credential-type (credential-id (string-ascii 64)))
  (map-get? credential-types { credential-id: credential-id })
)

;; Read-only function to get issued credential details
(define-read-only (get-issued-credential (student-id principal) (credential-id (string-ascii 64)))
  (map-get? issued-credentials { student-id: student-id, credential-id: credential-id })
)

;; Administrative function to change admin
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
