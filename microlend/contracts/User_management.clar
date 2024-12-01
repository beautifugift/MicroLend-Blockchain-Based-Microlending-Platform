;; User Management Contract for Lending Platform

;; Define constants
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ALREADY_REGISTERED (err u101))

;; Define the contract owner
(define-data-var contract-owner principal tx-sender)

;; Define data maps
(define-map borrowers
  { user-id: principal }
  {
    name: (string-utf8 50),
    identity-verified: bool,
    borrowing-needs: (string-utf8 500)
  }
)

(define-map lenders
  { user-id: principal }
  {
    name: (string-utf8 50)
  }
)

(define-map reputation-scores
  { user-id: principal }
  { score: uint }
)

;; Define public functions

;; Create borrower profile
(define-public (create-borrower-profile (name (string-utf8 50)) (borrowing-needs (string-utf8 500)))
  (let ((user tx-sender))
    (if (is-some (map-get? borrowers {user-id: user}))
      ERR_ALREADY_REGISTERED
      (begin
        (map-set borrowers
          {user-id: user}
          {
            name: name,
            identity-verified: false,
            borrowing-needs: borrowing-needs
          }
        )
        (map-set reputation-scores
          {user-id: user}
          {score: u100}  ;; Initial reputation score
        )
        (ok true)
      )
    )
  )
)

;; Create lender profile
(define-public (create-lender-profile (name (string-utf8 50)))
  (let ((user tx-sender))
    (if (is-some (map-get? lenders {user-id: user}))
      ERR_ALREADY_REGISTERED
      (begin
        (map-set lenders
          {user-id: user}
          {name: name}
        )
        (map-set reputation-scores
          {user-id: user}
          {score: u100}  ;; Initial reputation score
        )
        (ok true)
      )
    )
  )
)

;; Update borrower profile
(define-public (update-borrower-profile (borrowing-needs (string-utf8 500)))
  (let ((user tx-sender))
    (match (map-get? borrowers {user-id: user})
      profile (begin
        (map-set borrowers
          {user-id: user}
          (merge profile {borrowing-needs: borrowing-needs})
        )
        (ok true)
      )
      ERR_UNAUTHORIZED
    )
  )
)

;; Verify borrower identity (only contract owner can do this)
(define-public (verify-borrower-identity (borrower principal))
  (if (is-eq tx-sender (var-get contract-owner))
    (match (map-get? borrowers {user-id: borrower})
      profile (begin
        (map-set borrowers
          {user-id: borrower}
          (merge profile {identity-verified: true})
        )
        (ok true)
      )
      ERR_UNAUTHORIZED
    )
    ERR_UNAUTHORIZED
  )
)

;; Update reputation score (simplified version, in reality this would be more complex)
(define-public (update-reputation-score (user principal) (new-score uint))
  (if (is-eq tx-sender (var-get contract-owner))
    (begin
      (map-set reputation-scores
        {user-id: user}
        {score: new-score}
      )
      (ok true)
    )
    ERR_UNAUTHORIZED
  )
)

;; Read-only functions

;; Get borrower profile
(define-read-only (get-borrower-profile (user principal))
  (map-get? borrowers {user-id: user})
)

;; Get lender profile
(define-read-only (get-lender-profile (user principal))
  (map-get? lenders {user-id: user})
)

;; Get reputation score
(define-read-only (get-reputation-score (user principal))
  (default-to u0 (get score (map-get? reputation-scores {user-id: user})))
)

;; Get contract owner
(define-read-only (get-contract-owner)
  (var-get contract-owner)
)