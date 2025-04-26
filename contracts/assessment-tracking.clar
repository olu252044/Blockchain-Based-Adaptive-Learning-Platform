;; learning-path.clar
;; Contract to manage personalized learning paths

(define-data-var admin principal tx-sender)

;; Map of learning paths
(define-map learning-paths
  { path-id: (string-ascii 64) }
  {
    title: (string-utf8 64),
    description: (string-utf8 256),
    creator: principal,
    creation-time: uint,
    is-active: bool
  }
)

;; Map of content modules in a learning path
(define-map path-modules
  { path-id: (string-ascii 64), module-order: uint }
  {
    content-id: (string-ascii 64),
    prerequisite-modules: (list 10 uint), ;; List of module orders that are prerequisites
    assessment-id: (string-ascii 64)
  }
)

;; Map of student progress on learning paths
(define-map student-progress
  { student-id: principal, path-id: (string-ascii 64) }
  {
    current-module: uint,
    enrolled-time: uint,
    last-updated: uint,
    completed: bool
  }
)

;; Public function to create a new learning path
(define-public (create-learning-path
  (path-id (string-ascii 64))
  (title (string-utf8 64))
  (description (string-utf8 256)))
  (let
    ((creator tx-sender)
     (current-time (unwrap-panic (get-block-info? time (- block-height u1)))))
    (if (is-some (map-get? learning-paths { path-id: path-id }))
      (err u1) ;; Path ID already exists
      (begin
        (map-set learning-paths
          { path-id: path-id }
          {
            title: title,
            description: description,
            creator: creator,
            creation-time: current-time,
            is-active: true
          }
        )
        (ok true)
      )
    )
  )
)

;; Public function to add a module to a learning path
(define-public (add-path-module
  (path-id (string-ascii 64))
  (module-order uint)
  (content-id (string-ascii 64))
  (prerequisite-modules (list 10 uint))
  (assessment-id (string-ascii 64)))
  (let
    ((creator tx-sender))
    (begin
      (match (map-get? learning-paths { path-id: path-id })
        path-data (begin
          (asserts! (is-eq creator (get creator path-data)) (err u403))
          (map-set path-modules
            { path-id: path-id, module-order: module-order }
            {
              content-id: content-id,
              prerequisite-modules: prerequisite-modules,
              assessment-id: assessment-id
            }
          )
          (ok true)
        )
        (err u2) ;; Path not found
      )
    )
  )
)

;; Public function to enroll in a learning path
(define-public (enroll-in-path (path-id (string-ascii 64)))
  (let
    ((student-id tx-sender)
     (current-time (unwrap-panic (get-block-info? time (- block-height u1)))))
    (if (is-some (map-get? student-progress { student-id: student-id, path-id: path-id }))
      (err u3) ;; Already enrolled
      (begin
        (match (map-get? learning-paths { path-id: path-id })
          path-data (begin
            (asserts! (get is-active path-data) (err u4)) ;; Path must be active
            (map-set student-progress
              { student-id: student-id, path-id: path-id }
              {
                current-module: u0,
                enrolled-time: current-time,
                last-updated: current-time,
                completed: false
              }
            )
            (ok true)
          )
          (err u2) ;; Path not found
        )
      )
    )
  )
)

;; Public function to update student progress
(define-public (update-progress (path-id (string-ascii 64)) (module-order uint))
  (let
    ((student-id tx-sender)
     (current-time (unwrap-panic (get-block-info? time (- block-height u1)))))
    (match (map-get? student-progress { student-id: student-id, path-id: path-id })
      progress-data (begin
        (asserts! (< (get current-module progress-data) module-order) (err u5)) ;; Can only advance forward
        (map-set student-progress
          { student-id: student-id, path-id: path-id }
          (merge progress-data {
            current-module: module-order,
            last-updated: current-time,
            completed: false
          })
        )
        (ok true)
      )
      (err u6) ;; Not enrolled
    )
  )
)

;; Public function to mark a path as completed
(define-public (complete-path (path-id (string-ascii 64)))
  (let
    ((student-id tx-sender)
     (current-time (unwrap-panic (get-block-info? time (- block-height u1)))))
    (match (map-get? student-progress { student-id: student-id, path-id: path-id })
      progress-data (begin
        (map-set student-progress
          { student-id: student-id, path-id: path-id }
          (merge progress-data {
            last-updated: current-time,
            completed: true
          })
        )
        (ok true)
      )
      (err u6) ;; Not enrolled
    )
  )
)

;; Read-only function to get learning path details
(define-read-only (get-learning-path (path-id (string-ascii 64)))
  (map-get? learning-paths { path-id: path-id })
)

;; Read-only function to get path module details
(define-read-only (get-path-module (path-id (string-ascii 64)) (module-order uint))
  (map-get? path-modules { path-id: path-id, module-order: module-order })
)

;; Read-only function to get student progress
(define-read-only (get-student-progress (student-id principal) (path-id (string-ascii 64)))
  (map-get? student-progress { student-id: student-id, path-id: path-id })
)

;; Administrative function to deactivate a learning path
(define-public (deactivate-path (path-id (string-ascii 64)))
  (begin
    (match (map-get? learning-paths { path-id: path-id })
      path-data (begin
        (asserts! (or (is-eq tx-sender (var-get admin)) (is-eq tx-sender (get creator path-data))) (err u403))
        (map-set learning-paths
          { path-id: path-id }
          (merge path-data { is-active: false })
        )
        (ok true)
      )
      (err u2) ;; Path not found
    )
  )
)
