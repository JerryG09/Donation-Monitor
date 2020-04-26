pragma solidity >=0.4.22 <0.7.0;

contract CampaignFactory {
    Campaign[] public deployedCampaigns;
    constructor (uint minimum) public {
        Campaign newCampaign = new Campaign(minimum, msg.sender);
        deployedCampaigns.push(newCampaign);
    }
    function getDeployedCampaign()public view returns(Campaign[] memory) {
        return deployedCampaigns;
    }
}

contract Campaign {
    struct Request {
        string description;
        uint value;
        address payable recipient;
        bool complete;
        uint voteCount;
        mapping(address => bool) votes;
    }
    modifier restricted() {
        require(msg.sender == manager, 'You be a must be the manager');
        _;
    }
    Request[] public requests;
    address public manager;
    uint public minimumContribution;
    mapping(address => bool) public approvers;
    uint public approversCount;
    constructor (uint minimum, address creator) public {
        manager = creator;
        minimumContribution = minimum;
    }
    function contribute() public payable {
        require(msg.value > minimumContribution, 'amount below minimum contribution');
        approvers[msg.sender] = true;
        approversCount++;
    }
    function createRequest(string memory description, uint value, address payable recipient) public restricted {
        Request memory newRequest = Request({
            description: description,
            value: value,
            recipient: recipient,
            complete: false,
            voteCount: 0
        });
        requests.push(newRequest);
    }
    function approveRequest(uint index) public payable {
        Request storage request = requests[index];
        require(approvers[msg.sender], "must be one of the approvers");
        require(!request.votes[msg.sender], "this approver has voted for this request");

        request.votes[msg.sender] = true;
        request.voteCount++;
    }
    function finalizeRequest(uint index) public payable restricted {
        Request storage request = requests[index];
        require(request.voteCount > (approversCount / 2), "numner of vote must be atleast 51% of approvers");
        require(!request.complete, "request should not be completed");

        request.recipient.transfer(request.value);
        request.complete = true;
    }
}