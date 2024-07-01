// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Eventoken is ERC721Enumerable, Ownable {
    using Strings for uint256;

    struct Event {
        uint256 eventId;
        string name;
        string details;
        uint256 totalTickets;
        uint256 price;
        string eventImage;
        string ticketImage;
        address payable creator;
        uint256 ticketsSold;
    }

    struct Ticket {
        uint256 tokenId; // Unique token ID
        address owner;
        uint256 eventId;
        uint256 price;
        bool forSale;
    }

    mapping(uint256 => Event) public events;
    mapping(uint256 => uint256) public ticketsPerEvent;
    mapping(uint256 => mapping(address => uint256[])) public ticketsOwnedByEvent; // Changed to array of tokenIds
    mapping(uint256 => address) public ticketOwner;
    mapping(uint256 => uint256) public ticketToEvent;
    mapping(uint256 => Ticket) public tickets;
    mapping(uint256 => uint256) public lastTokenIdByEvent; // Track last token ID issued per event

    uint256 public nextEventId;
    uint256 public ticketCounter;

    event EventCreated(uint256 indexed eventId, string name, uint256 totalTickets, address indexed creator);
    event TicketMinted(address indexed owner, uint256 indexed eventId, uint256 indexed tokenId);
    event TicketTransferred(address indexed from, address indexed to, uint256 indexed tokenId);
    event TicketSold(address indexed from, address indexed to, uint256 indexed tokenId);
    event TicketListed(address indexed seller, uint256 indexed tokenId, uint256 price);
    event TicketRemovedFromSale(uint256 indexed tokenId);
    event TicketPurchased(address indexed seller, address indexed buyer, uint256 indexed tokenId, uint256 price);

    constructor() ERC721("Eventoken", "ETK") Ownable(msg.sender) {
        nextEventId = 1;
    }

    // Function to create a new event
    function createEvent(
        string memory _name,
        string memory _details,
        uint256 _totalTickets,
        uint256 _price,
        string memory _eventImage,
        string memory _ticketImage
    ) external {
        Event storage newEvent = events[nextEventId];
        newEvent.eventId = nextEventId;
        newEvent.name = _name;
        newEvent.details = _details;
        newEvent.totalTickets = _totalTickets;
        newEvent.price = _price;
        newEvent.eventImage = _eventImage;
        newEvent.ticketImage = _ticketImage;
        newEvent.creator = payable(msg.sender);
        
        emit EventCreated(nextEventId, _name, _totalTickets, msg.sender);
        nextEventId++;
    }

    // Function to buy tickets for a specific event
    function purchaseTickets(uint256 _eventId, uint256 _quantity) external payable {
        Event storage eventDetails = events[_eventId];
        require(eventDetails.totalTickets >= eventDetails.ticketsSold + _quantity, "Not enough tickets available");
        require(msg.value >= eventDetails.price * _quantity, "Insufficient funds");

        for (uint256 i = 0; i < _quantity; i++) {
            uint256 tokenId = ticketCounter + 1; // Generate new token ID
            _mint(msg.sender, tokenId); // Mint do token

            tickets[tokenId] = Ticket({
                tokenId: tokenId,
                owner: msg.sender,
                eventId: _eventId,
                price: eventDetails.price,
                forSale: false // By default, the ticket is not for sale when it is created
            });

            ticketsOwnedByEvent[_eventId][msg.sender].push(tokenId);
            ticketsPerEvent[_eventId]++;
            ticketOwner[tokenId] = msg.sender;
            ticketToEvent[tokenId] = _eventId;
            emit TicketMinted(msg.sender, _eventId, tokenId);
            ticketCounter++;
        }

        eventDetails.ticketsSold += _quantity;
        eventDetails.creator.transfer(msg.value);
    }

    // Function to transfer a ticket to another address
    function transferTicket(address _to, uint256 _tokenId) external {
        require(ownerOf(_tokenId) == msg.sender, "Not the owner of the ticket");
        safeTransferFrom(msg.sender, _to, _tokenId);
        ticketOwner[_tokenId] = _to;
        emit TicketTransferred(msg.sender, _to, _tokenId);
    }

    // Function to list a ticket for sale
    function listTicketForSale(uint256 _tokenId, uint256 _price) external {
        require(ownerOf(_tokenId) == msg.sender, "Not the owner of the ticket");
        require(!tickets[_tokenId].forSale, "Ticket is already listed for sale");

        tickets[_tokenId].forSale = true;
        tickets[_tokenId].price = _price;

        emit TicketListed(msg.sender, _tokenId, _price);
    }

    // Function to remove a ticket from the sale
    function removeTicketFromSale(uint256 _tokenId) external {
        require(ownerOf(_tokenId) == msg.sender, "Not the owner of the ticket");
        require(tickets[_tokenId].forSale, "Ticket is not currently for sale");

        tickets[_tokenId].forSale = false;
        tickets[_tokenId].price = 0;

        emit TicketRemovedFromSale(_tokenId);
    }

    // Function to buy a ticket that is on sale
    function buyTicket(uint256 _tokenId) external payable {
        Ticket storage saleTicket = tickets[_tokenId];
        require(msg.value >= saleTicket.price, "Insufficient payment");
        require(ownerOf(_tokenId) == saleTicket.owner, "Ticket seller is not the owner");

        address payable seller = payable(saleTicket.owner);
        seller.transfer(msg.value); // Transfer the payment to the seller

        safeTransferFrom(saleTicket.owner, msg.sender, _tokenId);
        ticketOwner[_tokenId] = msg.sender;

        // Clear ticket sale details
        saleTicket.forSale = false;
        saleTicket.price = 0;

        emit TicketPurchased(saleTicket.owner, msg.sender, _tokenId, saleTicket.price);
    }

    // Function to get all tickets on sale
    function getAllTicketsForSale() external view returns (Ticket[] memory) {
        uint256 forSaleCount = 0;
        for (uint256 i = 1; i <= ticketCounter; i++) {
            if (tickets[i].forSale) {
                forSaleCount++;
            }
        }
        
        Ticket[] memory result = new Ticket[](forSaleCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= ticketCounter; i++) {
            if (tickets[i].forSale) {
                result[index] = tickets[i];
                index++;
            }
        }

        return result;
    }

    // Function to calculate how many tickets are still available for an event
    function ticketsAvailable(uint256 _eventId) external view returns (uint256) {
        Event storage eventDetails = events[_eventId];
        return eventDetails.totalTickets - eventDetails.ticketsSold;
    }

    // Function to return the details of an event
    function getEventDetails(uint256 _eventId) external view returns (
        uint256, string memory, string memory, uint256, uint256, string memory, string memory, address, uint256
    ) {
        Event storage eventDetails = events[_eventId];
        return (
            eventDetails.eventId,
            eventDetails.name,
            eventDetails.details,
            eventDetails.totalTickets,
            eventDetails.price,
            eventDetails.eventImage,
            eventDetails.ticketImage,
            eventDetails.creator,
            eventDetails.ticketsSold
        );
    }

    // Function to return the tickets a user has for a specific event
    function getUserTickets(uint256 _eventId, address _user) external view returns (uint256[] memory) {
        return ticketsOwnedByEvent[_eventId][_user];
    }

    // Function to return all the tickets a user has
    function getUserAllTickets(address _user) external view returns (uint256[] memory) {
        uint256 totalTicketsCount = 0;
        
        // Count total tickets held by the user
        for (uint256 i = 1; i <= ticketCounter; i++) {
            if (tickets[i].owner == _user) {
                totalTicketsCount++;
            }
        }
        
        uint256[] memory userTickets = new uint256[](totalTicketsCount);
        uint256 counter = 0;

        // Get all ticket IDs owned by the user
        for (uint256 i = 1; i <= ticketCounter; i++) {
            if (tickets[i].owner == _user) {
                userTickets[counter] = tickets[i].tokenId;
                counter++;
            }
        }

        return userTickets;
    }

    // Function to get the event ID based on the ticket ID
    function getEventIdByTicket(uint256 _ticketId) external view returns (uint256) {
        return tickets[_ticketId].eventId;
    }

    function isForSale(uint256 _tokenId) external view returns (bool) {
        return tickets[_tokenId].forSale;
    }

    // Function to allow the contract to receive Ether
    receive() external payable {}

    // Function to remove Ether from the contract by the owner
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
