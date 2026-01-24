// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title NFTReservable
 * @dev Extension for token reservation before mint
 */
abstract contract NFTReservable {
    
    struct Reservation {
        address reserver;
        uint256 quantity;
        uint256 expiresAt;
        bool fulfilled;
    }
    
    mapping(address => Reservation) private _reservations;
    uint256 private _totalReserved;
    uint256 private _reservationPeriod = 1 hours;
    
    event TokensReserved(address indexed reserver, uint256 quantity, uint256 expiresAt);
    event ReservationFulfilled(address indexed reserver, uint256 quantity);
    event ReservationExpired(address indexed reserver, uint256 quantity);
    event ReservationPeriodUpdated(uint256 oldPeriod, uint256 newPeriod);
    
    /**
     * @dev Set reservation period
     */
    function _setReservationPeriod(uint256 period) internal {
        uint256 oldPeriod = _reservationPeriod;
        _reservationPeriod = period;
        emit ReservationPeriodUpdated(oldPeriod, period);
    }
    
    /**
     * @dev Reserve tokens for an address
     */
    function _reserve(address reserver, uint256 quantity) internal {
        require(quantity > 0, "Quantity must be > 0");
        require(_reservations[reserver].quantity == 0, "Already has reservation");
        
        uint256 expiresAt = block.timestamp + _reservationPeriod;
        
        _reservations[reserver] = Reservation({
            reserver: reserver,
            quantity: quantity,
            expiresAt: expiresAt,
            fulfilled: false
        });
        
        _totalReserved += quantity;
        emit TokensReserved(reserver, quantity, expiresAt);
    }
    
    /**
     * @dev Fulfill a reservation
     */
    function _fulfillReservation(address reserver) internal returns (uint256) {
        Reservation storage reservation = _reservations[reserver];
        
        require(reservation.quantity > 0, "No reservation");
        require(!reservation.fulfilled, "Already fulfilled");
        require(block.timestamp <= reservation.expiresAt, "Reservation expired");
        
        uint256 quantity = reservation.quantity;
        reservation.fulfilled = true;
        _totalReserved -= quantity;
        
        emit ReservationFulfilled(reserver, quantity);
        return quantity;
    }
    
    /**
     * @dev Cancel expired reservation
     */
    function _cancelExpiredReservation(address reserver) internal {
        Reservation storage reservation = _reservations[reserver];
        
        require(reservation.quantity > 0, "No reservation");
        require(!reservation.fulfilled, "Already fulfilled");
        require(block.timestamp > reservation.expiresAt, "Not expired");
        
        uint256 quantity = reservation.quantity;
        _totalReserved -= quantity;
        delete _reservations[reserver];
        
        emit ReservationExpired(reserver, quantity);
    }
    
    /**
     * @dev Get reservation for address
     */
    function getReservation(address reserver) public view returns (
        uint256 quantity,
        uint256 expiresAt,
        bool fulfilled,
        bool expired
    ) {
        Reservation memory reservation = _reservations[reserver];
        return (
            reservation.quantity,
            reservation.expiresAt,
            reservation.fulfilled,
            block.timestamp > reservation.expiresAt && !reservation.fulfilled
        );
    }
    
    /**
     * @dev Get total reserved tokens
     */
    function getTotalReserved() public view returns (uint256) {
        return _totalReserved;
    }
    
    /**
     * @dev Get reservation period
     */
    function getReservationPeriod() public view returns (uint256) {
        return _reservationPeriod;
    }
    
    /**
     * @dev Check if address has active reservation
     */
    function hasActiveReservation(address reserver) public view returns (bool) {
        Reservation memory reservation = _reservations[reserver];
        return reservation.quantity > 0 && 
               !reservation.fulfilled && 
               block.timestamp <= reservation.expiresAt;
    }
}
