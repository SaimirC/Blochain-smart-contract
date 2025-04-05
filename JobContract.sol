// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./EscrowContract.sol";

contract JobContract {
    struct Job {
        string description;
        uint budget;
        address client;
        address freelancer;
        bool isAssigned;
        bool isCompleted;
    }

    uint public nextJobId;
    mapping(uint => Job) public jobs;

    EscrowContract public escrow;

    event JobCreated(uint jobId, address client, string description, uint budget);
    event JobAssigned(uint jobId, address freelancer);
    event JobCompleted(uint jobId);

    constructor(address escrowAddress) {
        escrow = EscrowContract(payable(escrowAddress));
    }

    function createJob(string memory description, uint budget) external {
        jobs[nextJobId] = Job(description, budget, msg.sender, address(0), false, false);
        emit JobCreated(nextJobId, msg.sender, description, budget);
        nextJobId++;
    }

    function assignFreelancer(uint jobId, address freelancer) external payable {
        Job storage job = jobs[jobId];
        require(msg.sender == job.client, "Only client");
        require(!job.isAssigned, "Already assigned");
        require(msg.value == job.budget, "Incorrect amount");

        job.freelancer = freelancer;
        job.isAssigned = true;

        // Fund escrow
        escrow.createEscrow{value: msg.value}(jobId, freelancer);

        emit JobAssigned(jobId, freelancer);
    }

    function markJobCompleted(uint jobId) external {
        Job storage job = jobs[jobId];
        require(msg.sender == job.client, "Only client");
        require(job.isAssigned, "Not assigned");
        require(!job.isCompleted, "Already completed");

        job.isCompleted = true;

        // Release escrow
        escrow.releaseFunds(jobId);

        emit JobCompleted(jobId);
    }
}
