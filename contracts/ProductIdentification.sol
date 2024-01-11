// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "./Owned.sol";
import "./SampleToken.sol";

contract ProductIdentification is Owned {
    struct Product {
        address producer;
        string name;
    }

    uint private registrationTax;
    SampleToken private tokenContract;

    // Producer => bool
    mapping(address => bool) private producers;
    // Name => product
    mapping(string => Product) products;

    constructor(SampleToken _tokenContract, uint _registrationTax) {
        tokenContract = _tokenContract;
        registrationTax = _registrationTax;
    }

    function setRegistrationTax(uint newRegistrationTax) external onlyOwner {
        registrationTax = newRegistrationTax;
    }

    function getRegistrationTax() external view returns (uint) {
        return registrationTax;
    }

    // PRODUCERS

    function registerProducer() external {
        require(tokenContract.transferFrom(msg.sender, address(this), registrationTax));

        producers[msg.sender] = true;
    }

    function isProducerRegistered(address producerAddress) external view returns (bool) {
        return producers[producerAddress];
    }

    // PRODUCTS

    function registerProduct(Product calldata product) external returns (Product memory) {
        require(producers[msg.sender] == true, "Caller isn't a registered producer.");
        require(product.producer == msg.sender, "Product producer isn't the same as caller.");
        
        products[product.name] = product;

        return products[product.name];
    }

    function isProductRegistered(string calldata name) external view returns (bool) {
        return products[name].producer != address(0);
    }

    function getProduct(string calldata name) external view returns (Product memory) {
        require(products[name].producer != address(0), "Product does not exist");

        return products[name];
    }

    function collectTokens() external onlyOwner {
        require(tokenContract.transfer(owner, tokenContract.balanceOf(address(this))));
        payable(msg.sender).transfer(address(this).balance);
    }

    function getSampleToken() external view returns (SampleToken) {
        return tokenContract;
    }
}