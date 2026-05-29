// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title BaseNFTMarketplace
 * @dev Contrato de estudo para listagem e compra de NFTs na rede Base.
 */
contract BaseNFTMarketplace {
    
    struct Listing {
        address seller;
        uint256 price;
        bool isActive;
    }

    // Mapeamento: Endereço do Contrato NFT => Token ID => Detalhes da Listagem
    mapping(address => mapping(uint256 => Listing)) public listings;

    event NFTListed(address indexed seller, address indexed nftAddress, uint256 indexed tokenId, uint256 price);
    event NFTSold(address indexed buyer, address indexed nftAddress, uint256 indexed tokenId, uint256 price);
    event ListingCanceled(address indexed seller, address indexed nftAddress, uint256 indexed tokenId);

    /**
     * @dev Lista um NFT para venda no marketplace
     */
    function listNFT(address _nftAddress, uint256 _tokenId, uint256 _price) public {
        require(_price > 0, "O preco deve ser maior que zero");
        
        listings[_nftAddress][_tokenId] = Listing({
            seller: msg.sender,
            price: _price,
            isActive: true
        });

        emit NFTListed(msg.sender, _nftAddress, _tokenId, _price);
    }

    /**
     * @dev Compra um NFT que está listado
     */
    function buyNFT(address _nftAddress, uint256 _tokenId) public payable {
        Listing storage listing = listings[_nftAddress][_tokenId];
        
        require(listing.isActive, "Este NFT nao esta a venda");
        require(msg.value >= listing.price, "Saldo enviado insuficiente");

        address seller = listing.seller;
        uint256 price = listing.price;

        // Desativa a listagem antes de transferir o dinheiro (segurança contra reentrância)
        listing.isActive = false;

        // Transfere o valor para o vendedor
        payable(seller).transfer(price);

        emit NFTSold(msg.sender, _nftAddress, _tokenId, price);

        // Se sobrou troco, devolve para o comprador
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    /**
     * @dev Cancela a listagem de um NFT
     */
    function cancelListing(address _nftAddress, uint256 _tokenId) public {
        Listing storage listing = listings[_nftAddress][_tokenId];
        
        require(listing.seller == msg.sender, "Voce nao eh o dono desta listagem");
        require(listing.isActive, "Listagem ja esta inativa");

        listing.isActive = false;

        emit ListingCanceled(msg.sender, _nftAddress, _tokenId);
    }
}
