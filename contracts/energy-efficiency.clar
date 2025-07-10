;; Energy Efficiency Contract
;; Promotes LED and solar-powered lighting options

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u400))
(define-constant ERR_INVALID_AMOUNT (err u401))
(define-constant ERR_ASSESSMENT_NOT_FOUND (err u402))
(define-constant ERR_ALREADY_COMPLETED (err u403))
(define-constant ERR_INSUFFICIENT_BALANCE (err u404))
(define-constant ERR_INVALID_ASSESSOR (err u405))

;; Data Variables
(define-data-var efficiency-token-price uint u300000) ;; 0.3 STX in microSTX
(define-data-var next-assessment-id uint u1)
(define-data-var led-bonus-multiplier uint u150) ;; 1.5x bonus for LED
(define-data-var solar-bonus-multiplier uint u200) ;; 2x bonus for solar

;; Data Maps
(define-map efficiency-tokens principal uint)
(define-map efficiency-assessments uint {
    customer: principal,
    assessor: (optional principal),
    lighting-type: (string-ascii 20), ;; "LED", "Solar", "Incandescent", "Halogen"
    power-consumption: uint, ;; in watts
    estimated-annual-savings: uint, ;; in microSTX
    efficiency-rating: uint, ;; 1-10 scale
    environmental-impact-score: uint, ;; 1-10 scale
    bonus-earned: uint,
    completion-status: bool,
    created-at: uint,
    completed-at: (optional uint)
})
(define-map authorized-assessors principal bool)
(define-map assessor-ratings principal {total-rating: uint, rating-count: uint})
(define-map customer-total-savings principal uint)

;; Public Functions

;; Purchase energy efficiency assessment tokens
(define-public (purchase-tokens (amount uint))
    (let ((cost (* amount (var-get efficiency-token-price))))
        (asserts! (> amount u0) ERR_INVALID_AMOUNT)
        (try! (stx-transfer? cost tx-sender CONTRACT_OWNER))
        (map-set efficiency-tokens tx-sender
            (+ (default-to u0 (map-get? efficiency-tokens tx-sender)) amount))
        (ok amount)))

;; Create energy efficiency assessment request
(define-public (create-assessment (lighting-type (string-ascii 20)))
    (let ((assessment-id (var-get next-assessment-id))
          (customer-tokens (default-to u0 (map-get? efficiency-tokens tx-sender))))
        (asserts! (>= customer-tokens u1) ERR_INSUFFICIENT_BALANCE)
        (map-set efficiency-tokens tx-sender (- customer-tokens u1))
        (map-set efficiency-assessments assessment-id {
            customer: tx-sender,
            assessor: none,
            lighting-type: lighting-type,
            power-consumption: u0,
            estimated-annual-savings: u0,
            efficiency-rating: u0,
            environmental-impact-score: u0,
            bonus-earned: u0,
            completion-status: false,
            created-at: block-height,
            completed-at: none
        })
        (var-set next-assessment-id (+ assessment-id u1))
        (ok assessment-id)))

;; Assign assessor to assessment
(define-public (assign-assessor (assessment-id uint) (assessor principal))
    (let ((assessment (unwrap! (map-get? efficiency-assessments assessment-id) ERR_ASSESSMENT_NOT_FOUND)))
        (asserts! (is-eq tx-sender (get customer assessment)) ERR_NOT_AUTHORIZED)
        (asserts! (default-to false (map-get? authorized-assessors assessor)) ERR_INVALID_ASSESSOR)
        (asserts! (not (get completion-status assessment)) ERR_ALREADY_COMPLETED)
        (map-set efficiency-assessments assessment-id
            (merge assessment {assessor: (some assessor)}))
        (ok true)))

;; Complete energy efficiency assessment
(define-public (complete-assessment (assessment-id uint)
                                  (power-consumption uint)
                                  (estimated-annual-savings uint)
                                  (efficiency-rating uint)
                                  (environmental-impact-score uint))
    (let ((assessment (unwrap! (map-get? efficiency-assessments assessment-id) ERR_ASSESSMENT_NOT_FOUND))
          (bonus (calculate-efficiency-bonus (get lighting-type assessment) efficiency-rating)))
        (asserts! (is-some (get assessor assessment)) ERR_NOT_AUTHORIZED)
        (asserts! (is-eq tx-sender (unwrap-panic (get assessor assessment))) ERR_NOT_AUTHORIZED)
        (asserts! (not (get completion-status assessment)) ERR_ALREADY_COMPLETED)
        (asserts! (<= efficiency-rating u10) ERR_INVALID_AMOUNT)
        (asserts! (<= environmental-impact-score u10) ERR_INVALID_AMOUNT)

        ;; Update customer total savings
        (map-set customer-total-savings (get customer assessment)
            (+ (default-to u0 (map-get? customer-total-savings (get customer assessment)))
               estimated-annual-savings))

        ;; Complete assessment with bonus
        (map-set efficiency-assessments assessment-id
            (merge assessment {
                power-consumption: power-consumption,
                estimated-annual-savings: estimated-annual-savings,
                efficiency-rating: efficiency-rating,
                environmental-impact-score: environmental-impact-score,
                bonus-earned: bonus,
                completion-status: true,
                completed-at: (some block-height)
            }))

        ;; Award bonus tokens to customer
        (map-set efficiency-tokens (get customer assessment)
            (+ (default-to u0 (map-get? efficiency-tokens (get customer assessment))) bonus))

        (ok bonus)))

;; Rate assessor performance
(define-public (rate-assessor (assessor principal) (rating uint))
    (begin
        (asserts! (<= rating u5) ERR_INVALID_AMOUNT)
        (asserts! (>= rating u1) ERR_INVALID_AMOUNT)
        (let ((current-rating (default-to {total-rating: u0, rating-count: u0}
                              (map-get? assessor-ratings assessor))))
            (map-set assessor-ratings assessor {
                total-rating: (+ (get total-rating current-rating) rating),
                rating-count: (+ (get rating-count current-rating) u1)
            })
            (ok true))))

;; Admin function to authorize assessors
(define-public (authorize-assessor (assessor principal))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
        (map-set authorized-assessors assessor true)
        (ok true)))

;; Private Functions

(define-private (calculate-efficiency-bonus (lighting-type (string-ascii 20)) (efficiency-rating uint))
    (let ((base-bonus efficiency-rating))
        (if (is-eq lighting-type "LED")
            (/ (* base-bonus (var-get led-bonus-multiplier)) u100)
            (if (is-eq lighting-type "Solar")
                (/ (* base-bonus (var-get solar-bonus-multiplier)) u100)
                base-bonus))))

;; Read-only Functions

(define-read-only (get-token-balance (user principal))
    (default-to u0 (map-get? efficiency-tokens user)))

(define-read-only (get-assessment (assessment-id uint))
    (map-get? efficiency-assessments assessment-id))

(define-read-only (get-assessor-rating (assessor principal))
    (map-get? assessor-ratings assessor))

(define-read-only (is-authorized-assessor (assessor principal))
    (default-to false (map-get? authorized-assessors assessor)))

(define-read-only (get-assessment-price)
    (var-get efficiency-token-price))

(define-read-only (get-customer-total-savings (customer principal))
    (default-to u0 (map-get? customer-total-savings customer)))

(define-read-only (get-bonus-multipliers)
    {led: (var-get led-bonus-multiplier), solar: (var-get solar-bonus-multiplier)})
