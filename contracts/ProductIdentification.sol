// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "./Owned.sol";

contract ProductIdentification is Owned {
    struct Product {
        uint id;
        address producer;
        string name;
        uint volume;
    }

    uint private registrationTax;

    // Producer => bool
    mapping(address => bool) private producers;
    // ProductId => product
    mapping(uint => Product) products;
    // Product => last index for id
    uint currentProductIndex = 0;

    function setRegistrationTax(uint newRegistrationTax) external onlyOwner {
        registrationTax = newRegistrationTax;
    }

    function getRegistrationTax() external view returns (uint) {
        return registrationTax;
    }

    // PRODUCERS

    function registerProducer() external payable {
        require(msg.value >= registrationTax, "Not enough credits.");

        producers[msg.sender] = true;

        payable(msg.sender).transfer(msg.value - registrationTax);
        payable(owner).transfer(registrationTax);
    }

    function isProducerRegistered(address producerAddress) external view returns (bool) {
        return producers[producerAddress];
    }

    // PRODUCTS

    function registerProduct(Product calldata product) external returns (Product memory) {
        require(producers[msg.sender] == true, "Caller isn't a registered producer.");
        require(product.producer == msg.sender, "Product producer isn't the same as caller.");
        
        currentProductIndex = currentProductIndex + 1;
        uint productId = currentProductIndex;
        products[productId] = product;
        products[productId].id = productId;

        return products[productId];
    }

    function isProductRegistered(uint productId) external view returns (bool) {
        return products[productId].producer != address(0);
    }

    function getProduct(uint productId) external view returns (Product memory) {
        require(products[productId].producer != address(0), "Product does not exist");

        return products[productId];
    }
}