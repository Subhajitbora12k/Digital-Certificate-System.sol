
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Project {
    // Enum to define product states
    enum ProductState {
        Created,
        InTransit,
        Delivered,
        Verified
    }
    
    // Struct to represent a product
    struct Product {
        uint256 productId;
        string name;
        string description;
        address manufacturer;
        address currentOwner;
        ProductState state;
        uint256 createdAt;
        uint256 lastUpdated;
        string[] locationHistory;
        address[] ownerHistory;
    }
    
    // Struct to represent a stakeholder
    struct Stakeholder {
        address stakeholderAddress;
        string name;
        string role; // Manufacturer, Distributor, Retailer, Consumer
        bool isActive;
        uint256 registeredAt;
    }
    
    // State variables
    address public admin;
    uint256 public productCounter;
    uint256 public stakeholderCounter;
    
    // Mappings
    mapping(uint256 => Product) public products;
    mapping(address => Stakeholder) public stakeholders;
    mapping(address => bool) public authorizedStakeholders;
    mapping(uint256 => mapping(address => bool)) public productVerifiers;
    
    // Events
    event ProductCreated(uint256 indexed productId, string name, address indexed manufacturer);
    event ProductTransferred(uint256 indexed productId, address indexed from, address indexed to, string location);
    event ProductStateUpdated(uint256 indexed productId, ProductState newState);
    event StakeholderRegistered(address indexed stakeholder, string name, string role);
    event ProductVerified(uint256 indexed productId, address indexed verifier);
    
    // Modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }
    
    modifier onlyAuthorizedStakeholder() {
        require(authorizedStakeholders[msg.sender], "Only authorized stakeholders can perform this action");
        _;
    }
    
    modifier productExists(uint256 _productId) {
        require(_productId > 0 && _productId <= productCounter, "Product does not exist");
        _;
    }
    
    modifier onlyProductOwner(uint256 _productId) {
        require(products[_productId].currentOwner == msg.sender, "Only product owner can perform this action");
        _;
    }
    
    // Constructor
    constructor() {
        admin = msg.sender;
        productCounter = 0;
        stakeholderCounter = 0;
    }
    
    // Core Function 1: Create Product
    function createProduct(
        string memory _name,
        string memory _description,
        string memory _initialLocation
    ) public onlyAuthorizedStakeholder returns (uint256) {
        require(bytes(_name).length > 0, "Product name cannot be empty");
        require(bytes(_description).length > 0, "Product description cannot be empty");
        
        productCounter++;
        
        // Initialize location and owner history arrays
        string[] memory locationHistory = new string[](1);
        locationHistory[0] = _initialLocation;
        
        address[] memory ownerHistory = new address[](1);
        ownerHistory[0] = msg.sender;
        
        products[productCounter] = Product({
            productId: productCounter,
            name: _name,
            description: _description,
            manufacturer: msg.sender,
            currentOwner: msg.sender,
            state: ProductState.Created,
            createdAt: block.timestamp,
            lastUpdated: block.timestamp,
            locationHistory: locationHistory,
            ownerHistory: ownerHistory
        });
        
        emit ProductCreated(productCounter, _name, msg.sender);
        emit ProductStateUpdated(productCounter, ProductState.Created);
        
        return productCounter;
    }
    
    // Core Function 2: Transfer Product
    function transferProduct(
        uint256 _productId,
        address _newOwner,
        string memory _newLocation
    ) public productExists(_productId) onlyProductOwner(_productId) {
        require(_newOwner != address(0), "Invalid new owner address");
        require(authorizedStakeholders[_newOwner], "New owner must be an authorized stakeholder");
        require(bytes(_newLocation).length > 0, "Location cannot be empty");
        
        Product storage product = products[_productId];
        address previousOwner = product.currentOwner;
        
        // Update product ownership
        product.currentOwner = _newOwner;
        product.state = ProductState.InTransit;
        product.lastUpdated = block.timestamp;
        
        // Add to location and owner history
        product.locationHistory.push(_newLocation);
        product.ownerHistory.push(_newOwner);
        
        emit ProductTransferred(_productId, previousOwner, _newOwner, _newLocation);
        emit ProductStateUpdated(_productId, ProductState.InTransit);
    }
    
    // Core Function 3: Update Product State
    function updateProductState(
        uint256 _productId,
        ProductState _newState,
        string memory _location
    ) public productExists(_productId) onlyProductOwner(_productId) {
        require(bytes(_location).length > 0, "Location cannot be empty");
        
        Product storage product = products[_productId];
        require(product.state != _newState, "Product is already in this state");
        
        product.state = _newState;
        product.lastUpdated = block.timestamp;
        
        // Add location to history if provided
        if (bytes(_location).length > 0) {
            product.locationHistory.push(_location);
        }
        
        emit ProductStateUpdated(_productId, _newState);
    }
    
    // Register stakeholder function
    function registerStakeholder(
        address _stakeholder,
        string memory _name,
        string memory _role
    ) public onlyAdmin {
        require(_stakeholder != address(0), "Invalid stakeholder address");
        require(!authorizedStakeholders[_stakeholder], "Stakeholder already registered");
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(bytes(_role).length > 0, "Role cannot be empty");
        
        stakeholderCounter++;
        
        stakeholders[_stakeholder] = Stakeholder({
            stakeholderAddress: _stakeholder,
            name: _name,
            role: _role,
            isActive: true,
            registeredAt: block.timestamp
        });
        
        authorizedStakeholders[_stakeholder] = true;
        
        emit StakeholderRegistered(_stakeholder, _name, _role);
    }
    
    // Verify product authenticity
    function verifyProduct(uint256 _productId) public productExists(_productId) onlyAuthorizedStakeholder {
        require(!productVerifiers[_productId][msg.sender], "You have already verified this product");
        
        productVerifiers[_productId][msg.sender] = true;
        
        emit ProductVerified(_productId, msg.sender);
    }
    
    // Get product details
    function getProductDetails(uint256 _productId) public view productExists(_productId) returns (
        uint256 productId,
        string memory name,
        string memory description,
        address manufacturer,
        address currentOwner,
        ProductState state,
        uint256 createdAt,
        uint256 lastUpdated
    ) {
        Product memory product = products[_productId];
        return (
            product.productId,
            product.name,
            product.description,
            product.manufacturer,
            product.currentOwner,
            product.state,
            product.createdAt,
            product.lastUpdated
        );
    }
    
    // Get product location history
    function getLocationHistory(uint256 _productId) public view productExists(_productId) returns (string[] memory) {
        return products[_productId].locationHistory;
    }
    
    // Get product owner history
    function getOwnerHistory(uint256 _productId) public view productExists(_productId) returns (address[] memory) {
        return products[_productId].ownerHistory;
    }
    
    // Check if product is verified by specific address
    function isProductVerifiedBy(uint256 _productId, address _verifier) public view productExists(_productId) returns (bool) {
        return productVerifiers[_productId][_verifier];
    }
    
    // Get stakeholder details
    function getStakeholderDetails(address _stakeholder) public view returns (
        string memory name,
        string memory role,
        bool isActive,
        uint256 registeredAt
    ) {
        Stakeholder memory stakeholder = stakeholders[_stakeholder];
        return (
            stakeholder.name,
            stakeholder.role,
            stakeholder.isActive,
            stakeholder.registeredAt
        );
    }
    
    // Deactivate stakeholder (admin only)
    function deactivateStakeholder(address _stakeholder) public onlyAdmin {
        require(authorizedStakeholders[_stakeholder], "Stakeholder not found");
        
        stakeholders[_stakeholder].isActive = false;
        authorizedStakeholders[_stakeholder] = false;
    }
}
