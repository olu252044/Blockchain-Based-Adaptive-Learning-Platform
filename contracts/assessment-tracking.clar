;; assessment-tracking.clar
;; Contract to track student assessments and performance

(define-data-var admin principal tx-sender)

;; Map of assessment results
(define-map assessment-results
  { student-id: principal, assessment-id: (string-ascii 64) }
  {
    score: uint,
    passing-threshold: uint,
    completion-time: uint,
    verified-by: principal
  }
)

;; List of authorized assessors who can verify assessments
(define-map authorized-assessors
  { assessor-id: principal }
  { authorized: bool }
)

;; Initialize the contract owner as an authorized assessor
(map-set authorized-assessors { assessor-id: tx-sender } { authorized: true })

;; Public function to record an assessment result (only by authorized assessors)
(define-public (record-assessment
  (student-id principal)
  (assessment-id (string-ascii 64))
  (score uint)
  (passing-threshold uint))
  (let
    ((assessor tx-sender)
     (current-time (unwrap-panic (get-block-info? time (- block-height u1)))))
    (begin
      (asserts! (is-authorized-assessor assessor) (err u403))
      (map-set assessment-results
        { student-id: student-id, assessment-id: assessment-id }
        {
          score: score,
          passing-threshold: passing-threshold,
          completion-time: current-time,
          verified-by: assessor
        }
      )
      (ok true)
    )
  )
)

;; Read-only function to check if a student passed an assessment
(define-read-only (has-passed-assessment (student-id principal) (assessment-id (string-ascii 64)))
  (match (map-get? assessment-results { student-id: student-id, assessment-id: assessment-id })
    result (>= (get score result) (get passing-threshold result))
    false
  )
)

;; Read-only function to get assessment details
(define-read-only (get-assessment-result (student-id principal) (assessment-id (string-ascii 64)))
  (map-get? assessment-results { student-id: student-id, assessment-id: assessment-id })
)

;; Read-only function to check if an assessor is authorized
(define-read-only (is-authorized-assessor (assessor-id principal))
  (match (map-get? authorized-assessors { assessor-id: assessor-id })
    assessor-data (get authorized assessor-data)
    false
  )
)

;; Admin function to authorize an assessor
(define-public (authorize-assessor (assessor-id principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (map-set authorized-assessors { assessor-id: assessor-id } { authorized: true })
    (ok true)
  )
)

;; Admin function to revoke assessor authorization
(define-public (revoke-assessor (assessor-id principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (map-set authorized-assessors { assessor-id: assessor-id } { authorized: false })
    (ok true)
  )
)

;; Administrative function to change admin
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
