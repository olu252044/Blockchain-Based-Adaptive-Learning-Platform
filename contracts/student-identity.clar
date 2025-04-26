;; student-identity.clar
;; Contract to manage student identity and profiles

(define-data-var admin principal tx-sender)

;; Map of student profiles
(define-map student-profiles
  { student-id: principal }
  {
    name: (string-utf8 64),
    email: (string-utf8 128),
    creation-time: uint,
    updated-time: uint
  }
)

;; Public function to register a new student
(define-public (register-student (name (string-utf8 64)) (email (string-utf8 128)))
  (let
    ((student-id tx-sender)
     (current-time (unwrap-panic (get-block-info? time (- block-height u1)))))
    (if (is-registered student-id)
      (err u1) ;; Student already registered
      (begin
        (map-set student-profiles
          { student-id: student-id }
          {
            name: name,
            email: email,
            creation-time: current-time,
            updated-time: current-time
          }
        )
        (ok true)
      )
    )
  )
)

;; Public function to update student profile
(define-public (update-profile (name (string-utf8 64)) (email (string-utf8 128)))
  (let
    ((student-id tx-sender)
     (current-time (unwrap-panic (get-block-info? time (- block-height u1)))))
    (if (is-registered student-id)
      (begin
        (map-set student-profiles
          { student-id: student-id }
          {
            name: name,
            email: email,
            creation-time: (get creation-time (unwrap-panic (map-get? student-profiles { student-id: student-id }))),
            updated-time: current-time
          }
        )
        (ok true)
      )
      (err u2) ;; Student not registered
    )
  )
)

;; Read-only function to check if a student is registered
(define-read-only (is-registered (student-id principal))
  (is-some (map-get? student-profiles { student-id: student-id }))
)

;; Read-only function to get student profile
(define-read-only (get-student-profile (student-id principal))
  (map-get? student-profiles { student-id: student-id })
)

;; Administrative function to change admin
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
