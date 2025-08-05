;; Public Health Alert Distribution Contract
;; Notifies consumers of foodborne illness outbreaks and restaurant closures

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u500))
(define-constant ERR-ALERT-NOT-FOUND (err u501))
(define-constant ERR-INVALID-INPUT (err u502))
(define-constant ERR-ALREADY-EXISTS (err u503))
(define-constant ERR-ALERT-EXPIRED (err u504))

;; Data Variables
(define-data-var next-alert-id uint u1)
(define-data-var next-outbreak-id uint u1)

;; Data Maps
(define-map health-alerts
  { alert-id: uint }
  {
    alert-type: (string-ascii 30),
    severity-level: uint,
    title: (string-ascii 100),
    description: (string-ascii 500),
    affected-area: (string-ascii 100),
    issue-date: uint,
    expiry-date: uint,
    status: (string-ascii 20),
    issuing-authority: (string-ascii 100),
    contact-info: (string-ascii 200),
    related-restaurants: (list 20 (string-ascii 50))
  }
)

(define-map outbreak-investigations
  { outbreak-id: uint }
  {
    outbreak-type: (string-ascii 50),
    pathogen: (string-ascii 50),
    case-count: uint,
    hospitalization-count: uint,
    death-count: uint,
    investigation-start: uint,
    status: (string-ascii 20),
    source-identified: bool,
    suspected-restaurants: (list 10 (string-ascii 50)),
    confirmed-source: (optional (string-ascii 50)),
    investigation-notes: (string-ascii 1000)
  }
)

(define-map restaurant-closures
  { restaurant-id: (string-ascii 50) }
  {
    closure-date: uint,
    closure-reason: (string-ascii 200),
    closure-type: (string-ascii 20),
    expected-reopening: uint,
    actual-reopening: uint,
    closure-authority: (string-ascii 100),
    compliance-requirements: (string-ascii 500),
    status: (string-ascii 20)
  }
)

(define-map alert-subscriptions
  { subscriber-id: (string-ascii 50) }
  {
    notification-types: (list 10 (string-ascii 30)),
    geographic-areas: (list 5 (string-ascii 50)),
    contact-method: (string-ascii 20),
    contact-address: (string-ascii 200),
    active-status: bool,
    subscription-date: uint
  }
)

(define-map alert-distributions
  { alert-id: uint }
  {
    distribution-count: uint,
    distribution-date: uint,
    delivery-status: (string-ascii 20),
    failed-deliveries: uint
  }
)

;; Authorization Functions
(define-private (is-authorized (caller principal))
  (is-eq caller CONTRACT-OWNER))

(define-private (is-health-authority (caller principal))
  ;; In a real implementation, this would check against a registry of authorized health officials
  (is-eq caller CONTRACT-OWNER))

;; Alert Management Functions
(define-public (issue-health-alert
  (alert-type (string-ascii 30))
  (severity-level uint)
  (title (string-ascii 100))
  (description (string-ascii 500))
  (affected-area (string-ascii 100))
  (validity-blocks uint)
  (issuing-authority (string-ascii 100))
  (contact-info (string-ascii 200))
  (related-restaurants (list 20 (string-ascii 50))))
  (let
    (
      (alert-id (var-get next-alert-id))
      (current-time block-height)
      (expiry-time (+ current-time validity-blocks))
    )
    (asserts! (is-health-authority tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (> (len title) u0) ERR-INVALID-INPUT)
    (asserts! (> (len description) u0) ERR-INVALID-INPUT)
    (asserts! (and (>= severity-level u1) (<= severity-level u5)) ERR-INVALID-INPUT)
    (asserts! (> validity-blocks u0) ERR-INVALID-INPUT)

    (map-set health-alerts
      { alert-id: alert-id }
      {
        alert-type: alert-type,
        severity-level: severity-level,
        title: title,
        description: description,
        affected-area: affected-area,
        issue-date: current-time,
        expiry-date: expiry-time,
        status: "active",
        issuing-authority: issuing-authority,
        contact-info: contact-info,
        related-restaurants: related-restaurants
      }
    )

    ;; Trigger alert distribution
    (unwrap-panic (distribute-alert alert-id))

    (var-set next-alert-id (+ alert-id u1))
    (ok alert-id)
  )
)

(define-public (update-alert-status
  (alert-id uint)
  (new-status (string-ascii 20)))
  (let
    (
      (alert-data (unwrap! (map-get? health-alerts { alert-id: alert-id }) ERR-ALERT-NOT-FOUND))
    )
    (asserts! (is-health-authority tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (> (len new-status) u0) ERR-INVALID-INPUT)

    (map-set health-alerts
      { alert-id: alert-id }
      (merge alert-data { status: new-status })
    )
    (ok true)
  )
)

;; Outbreak Investigation Functions
(define-public (initiate-outbreak-investigation
  (outbreak-type (string-ascii 50))
  (pathogen (string-ascii 50))
  (initial-case-count uint)
  (suspected-restaurants (list 10 (string-ascii 50))))
  (let
    (
      (outbreak-id (var-get next-outbreak-id))
      (current-time block-height)
    )
    (asserts! (is-health-authority tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (> (len outbreak-type) u0) ERR-INVALID-INPUT)
    (asserts! (> initial-case-count u0) ERR-INVALID-INPUT)

    (map-set outbreak-investigations
      { outbreak-id: outbreak-id }
      {
        outbreak-type: outbreak-type,
        pathogen: pathogen,
        case-count: initial-case-count,
        hospitalization-count: u0,
        death-count: u0,
        investigation-start: current-time,
        status: "active",
        source-identified: false,
        suspected-restaurants: suspected-restaurants,
        confirmed-source: none,
        investigation-notes: ""
      }
    )

    (var-set next-outbreak-id (+ outbreak-id u1))
    (ok outbreak-id)
  )
)

(define-public (update-outbreak-investigation
  (outbreak-id uint)
  (case-count uint)
  (hospitalization-count uint)
  (death-count uint)
  (investigation-notes (string-ascii 1000)))
  (let
    (
      (outbreak-data (unwrap! (map-get? outbreak-investigations { outbreak-id: outbreak-id }) ERR-ALERT-NOT-FOUND))
    )
    (asserts! (is-health-authority tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (>= case-count (get case-count outbreak-data)) ERR-INVALID-INPUT)

    (map-set outbreak-investigations
      { outbreak-id: outbreak-id }
      (merge outbreak-data {
        case-count: case-count,
        hospitalization-count: hospitalization-count,
        death-count: death-count,
        investigation-notes: investigation-notes
      })
    )
    (ok true)
  )
)

(define-public (confirm-outbreak-source
  (outbreak-id uint)
  (confirmed-source (string-ascii 50)))
  (let
    (
      (outbreak-data (unwrap! (map-get? outbreak-investigations { outbreak-id: outbreak-id }) ERR-ALERT-NOT-FOUND))
    )
    (asserts! (is-health-authority tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (> (len confirmed-source) u0) ERR-INVALID-INPUT)

    (map-set outbreak-investigations
      { outbreak-id: outbreak-id }
      (merge outbreak-data {
        source-identified: true,
        confirmed-source: (some confirmed-source),
        status: "source-confirmed"
      })
    )
    (ok true)
  )
)

;; Restaurant Closure Management
(define-public (order-restaurant-closure
  (restaurant-id (string-ascii 50))
  (closure-reason (string-ascii 200))
  (closure-type (string-ascii 20))
  (compliance-requirements (string-ascii 500)))
  (let
    (
      (current-time block-height)
    )
    (asserts! (is-health-authority tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (> (len restaurant-id) u0) ERR-INVALID-INPUT)
    (asserts! (> (len closure-reason) u0) ERR-INVALID-INPUT)

    (map-set restaurant-closures
      { restaurant-id: restaurant-id }
      {
        closure-date: current-time,
        closure-reason: closure-reason,
        closure-type: closure-type,
        expected-reopening: u0,
        actual-reopening: u0,
        closure-authority: "Health Department",
        compliance-requirements: compliance-requirements,
        status: "closed"
      }
    )
    (ok true)
  )
)

(define-public (approve-restaurant-reopening
  (restaurant-id (string-ascii 50)))
  (let
    (
      (closure-data (unwrap! (map-get? restaurant-closures { restaurant-id: restaurant-id }) ERR-ALERT-NOT-FOUND))
      (current-time block-height)
    )
    (asserts! (is-health-authority tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status closure-data) "closed") ERR-INVALID-INPUT)

    (map-set restaurant-closures
      { restaurant-id: restaurant-id }
      (merge closure-data {
        actual-reopening: current-time,
        status: "reopened"
      })
    )
    (ok true)
  )
)

;; Subscription Management
(define-public (subscribe-to-alerts
  (subscriber-id (string-ascii 50))
  (notification-types (list 10 (string-ascii 30)))
  (geographic-areas (list 5 (string-ascii 50)))
  (contact-method (string-ascii 20))
  (contact-address (string-ascii 200)))
  (let
    (
      (current-time block-height)
    )
    (asserts! (> (len subscriber-id) u0) ERR-INVALID-INPUT)
    (asserts! (> (len contact-address) u0) ERR-INVALID-INPUT)

    (map-set alert-subscriptions
      { subscriber-id: subscriber-id }
      {
        notification-types: notification-types,
        geographic-areas: geographic-areas,
        contact-method: contact-method,
        contact-address: contact-address,
        active-status: true,
        subscription-date: current-time
      }
    )
    (ok true)
  )
)

(define-public (unsubscribe-from-alerts (subscriber-id (string-ascii 50)))
  (let
    (
      (subscription-data (unwrap! (map-get? alert-subscriptions { subscriber-id: subscriber-id }) ERR-ALERT-NOT-FOUND))
    )
    (map-set alert-subscriptions
      { subscriber-id: subscriber-id }
      (merge subscription-data { active-status: false })
    )
    (ok true)
  )
)

;; Alert Distribution Functions
(define-private (distribute-alert (alert-id uint))
  (let
    (
      (current-time block-height)
    )
    ;; In a real implementation, this would iterate through all active subscriptions
    ;; and send notifications based on subscription preferences
    (map-set alert-distributions
      { alert-id: alert-id }
      {
        distribution-count: u100, ;; Placeholder count
        distribution-date: current-time,
        delivery-status: "completed",
        failed-deliveries: u0
      }
    )
    (ok true)
  )
)

;; Query Functions
(define-read-only (get-health-alert (alert-id uint))
  (map-get? health-alerts { alert-id: alert-id })
)

(define-read-only (get-outbreak-investigation (outbreak-id uint))
  (map-get? outbreak-investigations { outbreak-id: outbreak-id })
)

(define-read-only (get-restaurant-closure (restaurant-id (string-ascii 50)))
  (map-get? restaurant-closures { restaurant-id: restaurant-id })
)

(define-read-only (get-alert-subscription (subscriber-id (string-ascii 50)))
  (map-get? alert-subscriptions { subscriber-id: subscriber-id })
)

(define-read-only (get-alert-distribution (alert-id uint))
  (map-get? alert-distributions { alert-id: alert-id })
)

(define-read-only (get-active-alerts (area (string-ascii 100)))
  ;; This would filter active alerts by geographic area
  ;; For now, returning a placeholder
  (ok "active-alerts-for-area")
)

(define-read-only (get-active-outbreaks)
  ;; This would return all ongoing outbreak investigations
  ;; For now, returning a placeholder
  (ok "active-outbreak-investigations")
)

(define-read-only (get-closed-restaurants (area (string-ascii 100)))
  ;; This would return all currently closed restaurants in an area
  ;; For now, returning a placeholder
  (ok "closed-restaurants-in-area")
)

(define-read-only (is-alert-active (alert-id uint))
  (match (map-get? health-alerts { alert-id: alert-id })
    alert-data
    (let
      (
        (current-time block-height)
        (expiry-date (get expiry-date alert-data))
        (status (get status alert-data))
      )
      (and (is-eq status "active") (< current-time expiry-date))
    )
    false
  )
)

(define-read-only (get-alert-statistics)
  ;; This would provide system-wide alert statistics
  ;; For now, returning placeholder data
  (ok {
    total-alerts-issued: u50,
    active-alerts: u5,
    total-outbreaks: u3,
    active-outbreaks: u1,
    total-closures: u12,
    current-closures: u2
  })
)
