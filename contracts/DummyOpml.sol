// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IOpml.sol";

// do not make this code open-sourced! fraud proof is dangerous!
contract DummyOpml is IOpml {

    address owner;
    address oracle;
    
    mapping(address => bool) public whitelist;

    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], "Address not whitelisted");
        _;
    }


    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    uint256 challengePeriod;

    constructor(){
        owner = msg.sender;
        whitelist[owner] = true;
        challengePeriod = 60; 
    }

    function updateChallengePeriod(uint256 _challengePeriod) external onlyOwner() {
        challengePeriod = _challengePeriod;
    }

    struct ChallengeData {
        // RequestId
        uint256 requestId;
        // Left bound of the binary search of i-th phase: challenger & defender agree on all steps <= L[i].
        mapping(uint256 => uint256) L;
        // Right bound of the binary search of i-th phase: challenger & defender disagree on all steps >= R[i].
        mapping(uint256 => uint256) R;
        // Maps step numbers to asserted state hashes for the challenger.
        mapping(uint256 => mapping(uint256 => bytes32)) assertedState;
        // Maps step numbers to asserted state hashes for the defender.
        mapping(uint256 => mapping(uint256 => bytes32)) defendedState;
        // Address of the submitter.
        address payable submitter;
        // Address of the challenger.
        address payable challenger;
        // Current challenge's phase
        uint256 currentPhase;
        // checkpoints
        mapping(uint256 => uint256) checkpoints;
        // stepcounts
        mapping(uint256 => uint256) stepcounts;
        // to next phase
        bool toNextPhase;
        // Hash of the output
        bytes32 outputHash;
    }

    /// @notice Maps challenge IDs to challenge dataS.
    mapping(uint256 => ChallengeData) public challenges;

    struct RequestData {
        bytes input;
        bytes32 modelHash;
        bytes32 programHash;
        bytes32 startState;
        bytes output;
        address submitter;
        uint256 challengeId;
        bool isInChallenge;
        uint256 submitBlockTime; // the block.number when uploadResult
    }


    mapping(uint256 => RequestData) public requests;

    mapping(uint256 => bool) public requestExists;

    mapping (bytes32 => mapping (bytes32 => bool)) modelExists;

    modifier ifRequestExists(uint256 requestId) {
        require(requestExists[requestId], "request does not exist");
        _;
    }

    /// @notice ID if the last created challenged, incremented for new challenge IDs.
    uint256 public lastChallengeId = 0;

    uint256 public lastRequestId = 0;

    function setLastRequestId(uint256 _lastRequestId) external onlyOwner() {
        lastRequestId = _lastRequestId;
    }

    // upload the AI model, the model and program should be in DA
    // upload model Hash, the inference program code Hash
    // TODO: unimplemented for DA
    function uploadModel(bytes32 modelHash, bytes32 programHash) external onlyWhitelisted {
        // require(!modelExists[modelHash][programHash], "the model already exists");
        modelExists[modelHash][programHash] = true;
    }

    // construct the start state for a AI model and user's input
    // TODO: unimplemented!
    function constructStartState(bytes32 modelHash, bytes32 programHash, bytes calldata input) internal pure returns (bytes32 startState) {
        startState = keccak256(abi.encodePacked(modelHash, programHash, input));
        return startState;
    }

    // we can construct the initialState using the input, can replace input with prompt (string)
    function initOpmlRequest(bytes32 modelHash, bytes32 programHash, bytes calldata input) external onlyWhitelisted returns (uint256 requestId) {
        require(modelExists[modelHash][programHash], "model does not exist");
        requestId = lastRequestId++;
        requestExists[requestId] = true;
        RequestData storage request = requests[requestId];
        request.input = input;
        request.modelHash = modelHash;
        request.programHash = programHash;
        request.startState = constructStartState(modelHash, programHash, input);
        return requestId;
    }

    /// @notice submitter should first upload the results and stake some money, waiting for the challenge process. Note that the results can only be set once (TODO)
    function uploadResult(uint256 requestId, bytes calldata output) public onlyWhitelisted ifRequestExists(requestId) {
        RequestData storage request = requests[requestId];
        require(request.output.length == 0, "to upload request, make sure that the request is never served by others. If you think the provided result is incorrect, please challenge it!");
        require(output.length != 0, "can not upload a zero-length output");
        request.submitBlockTime = block.number;
        request.output = output;
        request.submitter = msg.sender;
    }

    /// @notice If you think the provided result is incorrect, please challenge it!
    /// @return The challenge identifier
    function startChallenge(
        uint256 requestId,
        bytes calldata output,
        bytes32 finalState,
        uint256 stepCount
    ) external onlyWhitelisted ifRequestExists(requestId) returns (uint256) {
        RequestData storage request = requests[requestId];
        require(request.output.length != 0, "you can challenge only when someone upload incorrect result! This request has not been served yet. please upload result instead of challenge it");
        require(!isFinalized(requestId), "the request is finalized! can not challenge a finalized request");
        require(!request.isInChallenge, "the request is still in challenge, please wait for the end of the challenge");
        require(keccak256(request.output) != keccak256(output), "you should have a different output, otherwise, you agree with the submitter, do not challenge it");
        // TODO: check the outputHash is consistent with the finalState!
        request.isInChallenge = true;
        // Write input hash at predefined memory address.
        bytes32 startState = request.startState;

        uint256 challengeId = lastChallengeId++;
        ChallengeData storage c = challenges[challengeId];
        request.challengeId = challengeId;
        c.requestId = requestId;

        // A NEW CHALLENGER APPEARS
        c.outputHash = keccak256(output);
        c.challenger = payable(msg.sender);
        c.submitter = payable(request.submitter);
        // c.blockNumberN = blockNumberN; // no need to set the blockNumber
        c.assertedState[0][0] = startState;
        c.defendedState[0][0] = startState;
        c.assertedState[0][stepCount] = finalState;
        c.currentPhase = 0;
        c.L[0] = 0;
        c.R[0] = stepCount;

        c.stepcounts[c.currentPhase] = stepCount;
        c.toNextPhase = false;

        return challengeId;
    }

    function respondState(uint256 challengeId, bytes32 stateHash) onlyWhitelisted external {

    }

	function proposeState(uint256 challengeId, bytes32 stateHash) onlyWhitelisted external {

    }

	function assertStateTransition(uint256 challengeId) onlyWhitelisted external {

    }

    function isFinalized(uint256 requestId) public view ifRequestExists(requestId) returns (bool) {
        RequestData storage request = requests[requestId];
        return block.number - request.submitBlockTime >= challengePeriod;
        // return request.isFinalized;
    }

	function getOutput(uint256 requestId) external view ifRequestExists(requestId) returns (bytes memory output) {
        RequestData storage request = requests[requestId];
        require(request.output.length != 0, "output not uploaded");
        output =  request.output;
        return output;
    }

    function setOracleAddress(address _oracle) external onlyOwner {
        oracle = _oracle;
        whitelist[oracle] = true;
    }

    // Function to add an address to the whitelist
    function addToWhitelist(address _address) external onlyOwner {
        whitelist[_address] = true;
    }

    function removeFromWhitelist(address _address) external onlyOwner {
        whitelist[_address] = false;
    }

    function confirm(uint256 requestId, bytes32 responseHash) external {
        // TODO: Temporary placeholder code, formal code will be updated later.
        emit Confirm(requestId, responseHash);
    }
}