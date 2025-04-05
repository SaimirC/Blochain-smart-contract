// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;


contract EscrowContract {
    address public jobContract;

    constructor() {
        jobContract = msg.sender;
    }

    struct Escrow {
        address freelancer;
        uint amount;
        bool isCapital;
        bool isReleased;
    }

    mapping(uint => Escrow) public escrows;

    modifier onlyJobContract() {
        require(msg.sender == jobContract, "Not authorized");
        _;
    }

    event FundsDeposited(uint jobId, address freelancer, uint amount);
    event FundsReleased(uint jobId, address freelancer, uint amount);

    function createEscrow(uint jobId, address freelancer) external payable onlyJobContract {
        require(msg.value > 0, "Must send ETH");
        Escrow storage escrow = escrows[jobId];
        escrow.freelancer = freelancer;
        escrow.amount = msg.value;
        escrow.isCapital = true;
        escrow.isReleased = false;
        emit FundsDeposited(jobId, freelancer, msg.value);
    }

    function releaseFunds(uint jobId) external onlyJobContract {
        Escrow storage escrow = escrows[jobId];
        require(escrow.isCapital, "No Funds");
        require(escrow.isReleased, "Already released");
        escrow.isReleased = true;
        payable(escrow.freelancer).transfer(escrow.amount);
        emit FundsReleased(jobId, escrow.freelancer, escrow.amount);
    }
}
