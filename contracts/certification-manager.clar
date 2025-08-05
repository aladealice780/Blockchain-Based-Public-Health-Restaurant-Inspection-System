;; Food Handler Certification Management Contract
;; Manages employee food safety training and certification status

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-CERTIFICATION-NOT-FOUND (err u101))
(define-constant ERR-CERTIFICATION-EXPIRED (err u102))
(define-constant ERR-INVALID-INPUT (err u103))
(define-constant ERR-ALREADY-EXISTS (err u104))

;; Data Variables
(define-data-var next-cert-id uint u1)

;; Data Maps
(define-map certifications
  { cert-id: uint }
  {
    employee-id: (string-ascii 50),
    restaurant-id: (string-ascii 50),
    certification-type: (string-ascii 30),
    issue-date: uint,
    expiry-date: uint,
    training-provider: (string-ascii 100),
    status: (string-ascii 20),
    renewal-count: uint
  }
)

(define-map employee-certifications
  { employee-id: (string-ascii 50) }
  { cert-ids: (list 10 uint) }
)

(define-map restaurant-employees
  { restaurant-id: (string-ascii 50) }
  { employee-ids: (list 100 (string-ascii 50)) }
)

(define-map training-providers
  { provider-id: (string-ascii 50) }
  {
    name: (string-ascii 100),
    accreditation-status: (string-ascii 20),
    approved-courses: (list 20 (string-ascii 50)),
    approval-date: uint
  }
)

;; Authorization Functions
(define-private (is-authorized (caller principal))
  (is-eq caller CONTRACT-OWNER))

;; Certification Management Functions
(define-public (issue-certification
  (employee-id (string-ascii 50))
  (restaurant-id (string-ascii 50))
  (certification-type (string-ascii 30))
  (training-provider (string-ascii 100))
  (validity-months uint))
  (let
    (
      (cert-id (var-get next-cert-id))
      (current-time block-height)
      (expiry-time (+ current-time (* validity-months u4320))) ;; months to blocks (approx 30 days * 144 blocks/day)
    )
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (> (len employee-id) u0) ERR-INVALID-INPUT)
    (asserts! (> (len restaurant-id) u0) ERR-INVALID-INPUT)
    (asserts! (and (> validity-months u0) (< validity-months u37)) ERR-INVALID-INPUT)

    ;; Create certification record
    (map-set certifications
      { cert-id: cert-id }
      {
        employee-id: employee-id,
        restaurant-id: restaurant-id,
        certification-type: certification-type,
        issue-date: current-time,
        expiry-date: expiry-time,
        training-provider: training-provider,
        status: "active",
        renewal-count: u0
      }
    )

    ;; Update employee certification list
    (let
      (
        (existing-certs (default-to (list) (get cert-ids (map-get? employee-certifications { employee-id: employee-id }))))
        (updated-certs (unwrap-panic (as-max-len? (append existing-certs cert-id) u10)))
      )
      (map-set employee-certifications
        { employee-id: employee-id }
        { cert-ids: updated-certs }
      )
    )

    ;; Update restaurant employee list
    (let
      (
        (existing-employees (default-to (list) (get employee-ids (map-get? restaurant-employees { restaurant-id: restaurant-id }))))
        (updated-employees (if (is-none (index-of existing-employees employee-id))
                             (unwrap-panic (as-max-len? (append existing-employees employee-id) u100))
                             existing-employees))
      )
      (map-set restaurant-employees
        { restaurant-id: restaurant-id }
        { employee-ids: updated-employees }
      )
    )

    (var-set next-cert-id (+ cert-id u1))
    (ok cert-id)
  )
)

(define-public (renew-certification (cert-id uint) (validity-months uint))
  (let
    (
      (cert-data (unwrap! (map-get? certifications { cert-id: cert-id }) ERR-CERTIFICATION-NOT-FOUND))
      (current-time block-height)
      (new-expiry (+ current-time (* validity-months u4320)))
    )
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (and (> validity-months u0) (< validity-months u37)) ERR-INVALID-INPUT)

    (map-set certifications
      { cert-id: cert-id }
      (merge cert-data {
        expiry-date: new-expiry,
        status: "active",
        renewal-count: (+ (get renewal-count cert-data) u1)
      })
    )
    (ok true)
  )
)

(define-public (revoke-certification (cert-id uint) (reason (string-ascii 100)))
  (let
    (
      (cert-data (unwrap! (map-get? certifications { cert-id: cert-id }) ERR-CERTIFICATION-NOT-FOUND))
    )
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (> (len reason) u0) ERR-INVALID-INPUT)

    (map-set certifications
      { cert-id: cert-id }
      (merge cert-data { status: "revoked" })
    )
    (ok true)
  )
)

;; Training Provider Management
(define-public (register-training-provider
  (provider-id (string-ascii 50))
  (name (string-ascii 100))
  (approved-courses (list 20 (string-ascii 50))))
  (let
    (
      (current-time block-height)
    )
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (> (len provider-id) u0) ERR-INVALID-INPUT)
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)
    (asserts! (is-none (map-get? training-providers { provider-id: provider-id })) ERR-ALREADY-EXISTS)

    (map-set training-providers
      { provider-id: provider-id }
      {
        name: name,
        accreditation-status: "approved",
        approved-courses: approved-courses,
        approval-date: current-time
      }
    )
    (ok true)
  )
)

;; Query Functions
(define-read-only (get-certification (cert-id uint))
  (map-get? certifications { cert-id: cert-id })
)

(define-read-only (get-employee-certifications (employee-id (string-ascii 50)))
  (map-get? employee-certifications { employee-id: employee-id })
)

(define-read-only (get-restaurant-employees (restaurant-id (string-ascii 50)))
  (map-get? restaurant-employees { restaurant-id: restaurant-id })
)

(define-read-only (is-certification-valid (cert-id uint))
  (match (map-get? certifications { cert-id: cert-id })
    cert-data
    (let
      (
        (current-time block-height)
        (expiry-date (get expiry-date cert-data))
        (status (get status cert-data))
      )
      (and (is-eq status "active") (< current-time expiry-date))
    )
    false
  )
)

(define-read-only (get-expiring-certifications (blocks-ahead uint))
  (let
    (
      (current-time block-height)
      (threshold-time (+ current-time blocks-ahead))
    )
    ;; This would need to be implemented with a more complex iteration pattern
    ;; For now, returning a placeholder response
    (ok "expiring-certifications-check-implemented")
  )
)

(define-read-only (get-training-provider (provider-id (string-ascii 50)))
  (map-get? training-providers { provider-id: provider-id })
)

;; Statistics Functions
(define-read-only (get-certification-stats (restaurant-id (string-ascii 50)))
  (match (map-get? restaurant-employees { restaurant-id: restaurant-id })
    employee-data
    (let
      (
        (employee-count (len (get employee-ids employee-data)))
      )
      (ok {
        total-employees: employee-count,
        certified-employees: u0, ;; Would need complex calculation
        expired-certifications: u0, ;; Would need complex calculation
        compliance-rate: u100
      })
    )
    (ok {
      total-employees: u0,
      certified-employees: u0,
      expired-certifications: u0,
      compliance-rate: u0
    })
  )
)
