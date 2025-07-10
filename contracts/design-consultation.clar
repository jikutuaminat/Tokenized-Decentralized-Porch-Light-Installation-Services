;; Design Consultation Contract
;; Provides lighting style and placement recommendations

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u200))
(define-constant ERR_INVALID_AMOUNT (err u201))
(define-constant ERR_CONSULTATION_NOT_FOUND (err u202))
(define-constant ERR_ALREADY_COMPLETED (err u203))
(define-constant ERR_INSUFFICIENT_BALANCE (err u204))
(define-constant ERR_INVALID_CONSULTANT (err u205))

;; Data Variables
(define-data-var consultation-token-price uint u500000) ;; 0.5 STX in microSTX
(define-data-var next-consultation-id uint u1)

;; Data Maps
(define-map consultation-tokens principal uint)
(define-map design-consultations uint {
    customer: principal,
    consultant: (optional principal),
    style-preference: (string-ascii 100),
    placement-notes: (string-ascii 200),
    recommended-style: (optional (string-ascii 100)),
    recommended-placement: (optional (string-ascii 200)),
    completion-status: bool,
    customer-satisfaction: (optional uint),
    created-at: uint,
    completed-at: (optional uint)
})
(define-map authorized-consultants principal bool)
(define-map consultant-ratings principal {total-rating: uint, rating-count: uint})

;; Public Functions

;; Purchase design consultation tokens
(define-public (purchase-tokens (amount uint))
    (let ((cost (* amount (var-get consultation-token-price))))
        (asserts! (> amount u0) ERR_INVALID_AMOUNT)
        (try! (stx-transfer? cost tx-sender CONTRACT_OWNER))
        (map-set consultation-tokens tx-sender
            (+ (default-to u0 (map-get? consultation-tokens tx-sender)) amount))
        (ok amount)))

;; Create design consultation request
(define-public (create-consultation (style-preference (string-ascii 100)) (placement-notes (string-ascii 200)))
    (let ((consultation-id (var-get next-consultation-id))
          (customer-tokens (default-to u0 (map-get? consultation-tokens tx-sender))))
        (asserts! (>= customer-tokens u1) ERR_INSUFFICIENT_BALANCE)
        (map-set consultation-tokens tx-sender (- customer-tokens u1))
        (map-set design-consultations consultation-id {
            customer: tx-sender,
            consultant: none,
            style-preference: style-preference,
            placement-notes: placement-notes,
            recommended-style: none,
            recommended-placement: none,
            completion-status: false,
            customer-satisfaction: none,
            created-at: block-height,
            completed-at: none
        })
        (var-set next-consultation-id (+ consultation-id u1))
        (ok consultation-id)))

;; Assign consultant to consultation
(define-public (assign-consultant (consultation-id uint) (consultant principal))
    (let ((consultation (unwrap! (map-get? design-consultations consultation-id) ERR_CONSULTATION_NOT_FOUND)))
        (asserts! (is-eq tx-sender (get customer consultation)) ERR_NOT_AUTHORIZED)
        (asserts! (default-to false (map-get? authorized-consultants consultant)) ERR_INVALID_CONSULTANT)
        (asserts! (not (get completion-status consultation)) ERR_ALREADY_COMPLETED)
        (map-set design-consultations consultation-id
            (merge consultation {consultant: (some consultant)}))
        (ok true)))

;; Complete design consultation
(define-public (complete-consultation (consultation-id uint)
                                    (recommended-style (string-ascii 100))
                                    (recommended-placement (string-ascii 200)))
    (let ((consultation (unwrap! (map-get? design-consultations consultation-id) ERR_CONSULTATION_NOT_FOUND)))
        (asserts! (is-some (get consultant consultation)) ERR_NOT_AUTHORIZED)
        (asserts! (is-eq tx-sender (unwrap-panic (get consultant consultation))) ERR_NOT_AUTHORIZED)
        (asserts! (not (get completion-status consultation)) ERR_ALREADY_COMPLETED)
        (map-set design-consultations consultation-id
            (merge consultation {
                recommended-style: (some recommended-style),
                recommended-placement: (some recommended-placement),
                completion-status: true,
                completed-at: (some block-height)
            }))
        (ok true)))

;; Rate consultation satisfaction
(define-public (rate-consultation (consultation-id uint) (satisfaction-rating uint))
    (let ((consultation (unwrap! (map-get? design-consultations consultation-id) ERR_CONSULTATION_NOT_FOUND)))
        (asserts! (is-eq tx-sender (get customer consultation)) ERR_NOT_AUTHORIZED)
        (asserts! (get completion-status consultation) ERR_NOT_AUTHORIZED)
        (asserts! (<= satisfaction-rating u5) ERR_INVALID_AMOUNT)
        (asserts! (>= satisfaction-rating u1) ERR_INVALID_AMOUNT)
        (map-set design-consultations consultation-id
            (merge consultation {customer-satisfaction: (some satisfaction-rating)}))
        ;; Update consultant rating if consultant exists
        (match (get consultant consultation)
            consultant-principal
                (let ((current-rating (default-to {total-rating: u0, rating-count: u0}
                                      (map-get? consultant-ratings consultant-principal))))
                    (map-set consultant-ratings consultant-principal {
                        total-rating: (+ (get total-rating current-rating) satisfaction-rating),
                        rating-count: (+ (get rating-count current-rating) u1)
                    }))
            true)
        (ok true)))

;; Admin function to authorize consultants
(define-public (authorize-consultant (consultant principal))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
        (map-set authorized-consultants consultant true)
        (ok true)))

;; Read-only Functions

(define-read-only (get-token-balance (user principal))
    (default-to u0 (map-get? consultation-tokens user)))

(define-read-only (get-consultation (consultation-id uint))
    (map-get? design-consultations consultation-id))

(define-read-only (get-consultant-rating (consultant principal))
    (map-get? consultant-ratings consultant))

(define-read-only (is-authorized-consultant (consultant principal))
    (default-to false (map-get? authorized-consultants consultant)))

(define-read-only (get-consultation-price)
    (var-get consultation-token-price))
