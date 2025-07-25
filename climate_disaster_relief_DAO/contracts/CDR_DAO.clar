;; Climate Disaster Relief DAO Contract
;; Manages decentralized disaster relief funds with transparent voting

;; Define constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-already-voted (err u101))
(define-constant err-proposal-expired (err u102))
(define-constant err-invalid-amount (err u103))
(define-constant err-insufficient-funds (err u104))
(define-constant err-proposal-not-found (err u105))
(define-constant err-proposal-not-passed (err u106))

;; Define data variables
(define-data-var proposal-counter uint u0)
(define-data-var treasury-balance uint u0)
(define-data-var quorum-percentage uint u51) ;; 51% required to pass

;; Define maps
(define-map proposals
    uint
    {
        proposer: principal,
        recipient: principal,
        amount: uint,
        description: (string-utf8 500),
        yes-votes: uint,
        no-votes: uint,
        end-block: uint,
        executed: bool
    }
)

(define-map member-votes
    { proposal-id: uint, member: principal }
    bool
)

(define-map members principal bool)

;; Read-only functions
(define-read-only (get-proposal (proposal-id uint))
    (map-get? proposals proposal-id)
)

(define-read-only (has-voted (proposal-id uint) (member principal))
    (default-to false (map-get? member-votes { proposal-id: proposal-id, member: member }))
)

(define-read-only (is-member (address principal))
    (default-to false (map-get? members address))
)

(define-read-only (get-treasury-balance)
    (var-get treasury-balance)
)

;; Public functions
(define-public (add-member (new-member principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (map-set members new-member true))
    )
)

(define-public (donate (amount uint))
    (begin
        (asserts! (> amount u0) err-invalid-amount)
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        (var-set treasury-balance (+ (var-get treasury-balance) amount))
        (ok true)
    )
)

(define-public (create-proposal (recipient principal) (amount uint) (description (string-utf8 500)))
    (let
        (
            (proposal-id (+ (var-get proposal-counter) u1))
        )
        (asserts! (is-member tx-sender) err-owner-only)
        (asserts! (<= amount (var-get treasury-balance)) err-insufficient-funds)
        (map-set proposals proposal-id {
            proposer: tx-sender,
            recipient: recipient,
            amount: amount,
            description: description,
            yes-votes: u0,
            no-votes: u0,
            end-block: (+ stacks-block-height u1440), ;; ~10 days
            executed: false
        })
        (var-set proposal-counter proposal-id)
        (ok proposal-id)
    )
)

(define-public (vote (proposal-id uint) (vote-yes bool))
    (let
        (
            (proposal (unwrap! (get-proposal proposal-id) err-proposal-not-found))
            (voted (has-voted proposal-id tx-sender))
        )
        (asserts! (is-member tx-sender) err-owner-only)
        (asserts! (not voted) err-already-voted)
        (asserts! (< stacks-block-height (get end-block proposal)) err-proposal-expired)
        
        (map-set member-votes { proposal-id: proposal-id, member: tx-sender } true)
        
        (if vote-yes
            (map-set proposals proposal-id 
                (merge proposal { yes-votes: (+ (get yes-votes proposal) u1) })
            )
            (map-set proposals proposal-id 
                (merge proposal { no-votes: (+ (get no-votes proposal) u1) })
            )
        )
        (ok true)
    )
)

(define-public (execute-proposal (proposal-id uint))
    (let
        (
            (proposal (unwrap! (get-proposal proposal-id) err-proposal-not-found))
            (total-votes (+ (get yes-votes proposal) (get no-votes proposal)))
            (approval-percentage (if (> total-votes u0)
                                    (/ (* (get yes-votes proposal) u100) total-votes)
                                    u0))
        )
        (asserts! (>= stacks-block-height (get end-block proposal)) err-proposal-expired)
        (asserts! (not (get executed proposal)) err-owner-only)
        (asserts! (>= approval-percentage (var-get quorum-percentage)) err-proposal-not-passed)
        
        (try! (as-contract (stx-transfer? (get amount proposal) tx-sender (get recipient proposal))))
        (var-set treasury-balance (- (var-get treasury-balance) (get amount proposal)))
        (map-set proposals proposal-id (merge proposal { executed: true }))
        (ok true)
    )
)