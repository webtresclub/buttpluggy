// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {GasSnapshot} from "forge-gas-snapshot/GasSnapshot.sol";
import "foundry-huff/HuffDeployer.sol";
import {ERC721TokenReceiver} from "solmate/tokens/ERC721.sol";

import "../src/IUwU.sol";

contract ERC721Recipient is ERC721TokenReceiver {
    address public operator;
    address public from;
    uint256 public id;
    bytes public data;

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _id,
        bytes calldata _data
    ) public virtual override returns (bytes4) {
        operator = _operator;
        from = _from;
        id = _id;
        data = _data;

        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

contract RevertingERC721Recipient is ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public virtual override returns (bytes4) {
        revert(string(abi.encodePacked(ERC721TokenReceiver.onERC721Received.selector)));
    }
}

contract WrongReturnDataERC721Recipient is ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public virtual override returns (bytes4) {
        return 0xCAFEBEEF;
    }
}

contract NonERC721Recipient {}


contract ERC721Test is Test {
    IUwU token;

    function setUp() public {
        token = IUwU(HuffDeployer.config().with_addr_constant("OWNER", address(this)).deploy("Buttpluggy"));
    }

    //function invariantMetadata() public {
    function testMetadata() public {
        assertEq(token.name(), "Buttpluggy");
        assertEq(token.symbol(), "UwU");
    }

    function testMint() public {
        token.plug(address(0xBEEF), 1337);

        assertEq(token.balanceOf(address(0xBEEF)), 1);
        assertEq(token.ownerOf(1337), address(0xBEEF));
    }

    function testNoBurn() public {
        token.plug(address(0xBEEF), 1337);
        
        (bool ret, ) = address(token).call(abi.encodeWithSignature("burn(uint256)", 1337));
        assertEq(ret, false, "burn should fail");

        assertEq(token.balanceOf(address(0xBEEF)), 1);
    }

    function testApprove() public {
        token.plug(address(this), 1337);

        token.approve(address(0xBEEF), 1337);

        assertEq(token.getApproved(1337), address(0xBEEF));
    }

    function testApproveBurn() public {
        token.plug(address(this), 1337);

        token.approve(address(0xBEEF), 1337);

        (bool ret, ) = address(token).call(abi.encodeWithSignature("burn(uint256)", 1337));
        assertEq(ret, false, "burn should fail");
    }

    function testApproveAll() public {
        token.setApprovalForAll(address(0xBEEF), true);

        assertTrue(token.isApprovedForAll(address(this), address(0xBEEF)));
    }

    function testTransferFrom() public {
        address from = address(0xABCD);

        token.plug(from, 1337);

        vm.prank(from);
        token.approve(address(this), 1337);

        token.transferFrom(from, address(0xBEEF), 1337);

        assertEq(token.getApproved(1337), address(0));
        assertEq(token.ownerOf(1337), address(0xBEEF));
        assertEq(token.balanceOf(address(0xBEEF)), 1);
        assertEq(token.balanceOf(from), 0);
    }

    function testTransferFromSelf() public {
        token.plug(address(this), 1337);

        token.transferFrom(address(this), address(0xBEEF), 1337);

        assertEq(token.getApproved(1337), address(0));
        assertEq(token.ownerOf(1337), address(0xBEEF));
        assertEq(token.balanceOf(address(0xBEEF)), 1);
        assertEq(token.balanceOf(address(this)), 0);
    }

    function testTransferFromApproveAll() public {
        address from = address(0xABCD);

        token.plug(from, 1337);

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.transferFrom(from, address(0xBEEF), 1337);

        assertEq(token.getApproved(1337), address(0));
        assertEq(token.ownerOf(1337), address(0xBEEF));
        assertEq(token.balanceOf(address(0xBEEF)), 1);
        assertEq(token.balanceOf(from), 0);
    }

    function testSafeTransferFromToEOA() public {
        address from = address(0xABCD);

        token.plug(from, 1337);

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeTransferFrom(from, address(0xBEEF), 1337);

        assertEq(token.getApproved(1337), address(0));
        assertEq(token.ownerOf(1337), address(0xBEEF));
        assertEq(token.balanceOf(address(0xBEEF)), 1);
        assertEq(token.balanceOf(from), 0);
    }

    function testSafeTransferFromToERC721Recipient() public {
        address from = address(0xABCD);
        ERC721Recipient recipient = new ERC721Recipient();

        token.plug(from, 1337);

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeTransferFrom(from, address(recipient), 1337);

        assertEq(token.getApproved(1337), address(0));
        assertEq(token.ownerOf(1337), address(recipient));
        assertEq(token.balanceOf(address(recipient)), 1);
        assertEq(token.balanceOf(from), 0);

        assertEq(recipient.operator(), address(this));
        assertEq(recipient.from(), from);
        assertEq(recipient.id(), 1337);
        assertEq(keccak256(recipient.data()), keccak256(""));
    }

    function testSafeTransferFromToERC721RecipientWithData() public {
        address from = address(0xABCD);
        ERC721Recipient recipient = new ERC721Recipient();

        token.plug(from, 1337);

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeTransferFrom(from, address(recipient), 1337, "testing 123");

        assertEq(token.getApproved(1337), address(0));
        assertEq(token.ownerOf(1337), address(recipient));
        assertEq(token.balanceOf(address(recipient)), 1);
        assertEq(token.balanceOf(from), 0);

        assertEq(recipient.operator(), address(this));
        assertEq(recipient.from(), from);
        assertEq(recipient.id(), 1337);
        assertEq(keccak256(recipient.data()), keccak256("testing 123"));
    }

    function testFailMintToZero() public {
        token.plug(address(0), 1337);
    }

    function testFailDoubleMint() public {
        token.plug(address(0xBEEF), 1337);
        token.plug(address(0xBEEF), 1337);
    }

    function testBurnUnMinted() public {
        (bool ret, ) = address(token).call(abi.encodeWithSignature("burn(uint256)", 1337));
        assertEq(ret, false, "burn should fail");
    }

    function testFailApproveUnMinted() public {
        token.approve(address(0xBEEF), 1337);
    }

    function testFailApproveUnAuthorized() public {
        token.plug(address(0xCAFE), 1337);

        token.approve(address(0xBEEF), 1337);
    }

    function testFailTransferFromUnOwned() public {
        token.transferFrom(address(0xFEED), address(0xBEEF), 1337);
    }

    function testFailTransferFromWrongFrom() public {
        token.plug(address(0xCAFE), 1337);

        token.transferFrom(address(0xFEED), address(0xBEEF), 1337);
    }

    function testFailTransferFromToZero() public {
        token.plug(address(this), 1337);

        token.transferFrom(address(this), address(0), 1337);
    }

    function testFailTransferFromNotOwner() public {
        token.plug(address(0xFEED), 1337);

        token.transferFrom(address(0xFEED), address(0xBEEF), 1337);
    }

    function testFailSafeTransferFromToNonERC721Recipient() public {
        token.plug(address(this), 1337);

        token.safeTransferFrom(address(this), address(new NonERC721Recipient()), 1337);
    }

    function testFailSafeTransferFromToNonERC721RecipientWithData() public {
        token.plug(address(this), 1337);

        token.safeTransferFrom(address(this), address(new NonERC721Recipient()), 1337, "testing 123");
    }

    function testFailSafeTransferFromToRevertingERC721Recipient() public {
        token.plug(address(this), 1337);

        token.safeTransferFrom(address(this), address(new RevertingERC721Recipient()), 1337);
    }

    function testFailSafeTransferFromToRevertingERC721RecipientWithData() public {
        token.plug(address(this), 1337);

        token.safeTransferFrom(address(this), address(new RevertingERC721Recipient()), 1337, "testing 123");
    }

    function testFailSafeTransferFromToERC721RecipientWithWrongReturnData() public {
        token.plug(address(this), 1337);

        token.safeTransferFrom(address(this), address(new WrongReturnDataERC721Recipient()), 1337);
    }

    function testFailSafeTransferFromToERC721RecipientWithWrongReturnDataWithData() public {
        token.plug(address(this), 1337);

        token.safeTransferFrom(address(this), address(new WrongReturnDataERC721Recipient()), 1337, "testing 123");
    }

    function testSafeMintToNonERC721Recipient() public {
        token.plug(address(new NonERC721Recipient()), 1337);
    }

    function testSafeMintToRevertingERC721Recipient() public {
        token.plug(address(new RevertingERC721Recipient()), 1337);
    }

    function testSafeMintToERC721RecipientWithWrongReturnData() public {
        token.plug(address(new WrongReturnDataERC721Recipient()), 1337);
    }
    
    function testBalanceOfZeroAddress() public {
        uint256 bal = token.balanceOf(address(0));
        assertEq(0, bal);
    }

    /*
    this instead of fail will always be 0
    // @todo review
    function testFailOwnerOfUnminted() public view {
        token.ownerOf(1337);
    }
    */

    function testMintSimple() public {
        address beef = address(0xBEEF);
        token.plug(beef, 1);
        
        vm.expectRevert();
        token.plug(beef, 1);

        /*
        vm.expectRevert();
        token.plug(beef, 0);
        */
        vm.expectRevert();
        token.plug(address(0), 1);

        vm.expectRevert();
        vm.prank(beef);
        token.plug(beef, 2);
    }

    function testMint(address to, uint256 id) public {
        if (to == address(0)) to = address(0xBEEF);

        token.plug(to, id);

        assertEq(token.balanceOf(to), 1);
        assertEq(token.ownerOf(id), to);
    }

    function testApprove(address to, uint256 id) public {
        if (to == address(0)) to = address(0xBEEF);

        token.plug(address(this), id);

        token.approve(to, id);

        assertEq(token.getApproved(id), to);
    }

    function testApproveBurn(address to, uint256 id) public {
        token.plug(address(this), id);

        token.approve(address(to), id);

        (bool ret, ) = address(token).call(abi.encodeWithSignature("burn(uint256)", id));
        assertEq(ret, false, "burn should fail");
    }

    function testApproveAll(address to, bool approved) public {
        token.setApprovalForAll(to, approved);

        assertEq(token.isApprovedForAll(address(this), to), approved);
    }

    function testTransferFrom(uint256 id, address to) public {
        address from = address(0xABCD);

        if (to == address(0) || to == from) to = address(0xBEEF);

        token.plug(from, id);

        vm.prank(from);
        token.approve(address(this), id);

        token.transferFrom(from, to, id);

        assertEq(token.getApproved(id), address(0));
        assertEq(token.ownerOf(id), to);
        assertEq(token.balanceOf(to), 1);
        assertEq(token.balanceOf(from), 0);
    }

    function testTransferFromSelf(uint256 id, address to) public {
        if (to == address(0) || to == address(this)) to = address(0xBEEF);

        token.plug(address(this), id);

        token.transferFrom(address(this), to, id);

        assertEq(token.getApproved(id), address(0));
        assertEq(token.ownerOf(id), to);
        assertEq(token.balanceOf(to), 1);
        assertEq(token.balanceOf(address(this)), 0);
    }

    function testTransferFromApproveAll(uint256 id, address to) public {
        address from = address(0xABCD);

        if (to == address(0) || to == from) to = address(0xBEEF);

        token.plug(from, id);

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.transferFrom(from, to, id);

        assertEq(token.getApproved(id), address(0));
        assertEq(token.ownerOf(id), to);
        assertEq(token.balanceOf(to), 1);
        assertEq(token.balanceOf(from), 0);
    }

    function testSafeTransferFromToEOA(uint256 id, address to) public {
        address from = address(0xABCD);

        if (to == address(0) || to == from) to = address(0xBEEF);

        if (uint256(uint160(to)) <= 18 || to.code.length > 0) return;

        token.plug(from, id);

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeTransferFrom(from, to, id);

        assertEq(token.getApproved(id), address(0));
        assertEq(token.ownerOf(id), to);
        assertEq(token.balanceOf(to), 1);
        assertEq(token.balanceOf(from), 0);
    }

    function testSafeTransferFromToERC721Recipient(uint256 id) public {
        address from = address(0xABCD);

        ERC721Recipient recipient = new ERC721Recipient();

        token.plug(from, id);

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeTransferFrom(from, address(recipient), id);

        assertEq(token.getApproved(id), address(0));
        assertEq(token.ownerOf(id), address(recipient));
        assertEq(token.balanceOf(address(recipient)), 1);
        assertEq(token.balanceOf(from), 0);

        assertEq(recipient.operator(), address(this));
        assertEq(recipient.from(), from);
        assertEq(recipient.id(), id);
        assertEq(keccak256(recipient.data()), keccak256(""));
    }

    function testSafeTransferFromToERC721RecipientWithData(uint256 id, bytes calldata data) public {
        address from = address(0xABCD);
        ERC721Recipient recipient = new ERC721Recipient();

        token.plug(from, id);

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeTransferFrom(from, address(recipient), id, data);

        assertEq(token.getApproved(id), address(0));
        assertEq(token.ownerOf(id), address(recipient));
        assertEq(token.balanceOf(address(recipient)), 1);
        assertEq(token.balanceOf(from), 0);

        assertEq(recipient.operator(), address(this));
        assertEq(recipient.from(), from);
        assertEq(recipient.id(), id);
        assertEq(keccak256(recipient.data()), keccak256(data));
    }

    function testFailMintToZero(uint256 id) public {
        token.plug(address(0), id);
    }

    function testFailDoubleMint(uint256 id, address to) public {
        if (to == address(0)) to = address(0xBEEF);

        token.plug(to, id);
        token.plug(to, id);
    }

    function testFailApproveUnMinted(uint256 id, address to) public {
        token.approve(to, id);
    }

    function testFailApproveUnAuthorized(
        address owner,
        uint256 id,
        address to
    ) public {
        if (owner == address(0) || owner == address(this)) owner = address(0xBEEF);

        token.plug(owner, id);

        token.approve(to, id);
    }

    function testFailTransferFromUnOwned(
        address from,
        address to,
        uint256 id
    ) public {
        token.transferFrom(from, to, id);
    }

    function testFailTransferFromWrongFrom(
        address owner,
        address from,
        address to,
        uint256 id
    ) public {
        if (owner == address(0)) to = address(0xBEEF);
        if (from == owner) revert();

        token.plug(owner, id);

        token.transferFrom(from, to, id);
    }

    function testFailTransferFromToZero(uint256 id) public {
        token.plug(address(this), id);

        token.transferFrom(address(this), address(0), id);
    }

    function testFailTransferFromNotOwner(
        address from,
        address to,
        uint256 id
    ) public {
        if (from == address(this)) from = address(0xBEEF);

        token.plug(from, id);

        token.transferFrom(from, to, id);
    }

    function testFailSafeTransferFromToNonERC721Recipient(uint256 id) public {
        token.plug(address(this), id);

        token.safeTransferFrom(address(this), address(new NonERC721Recipient()), id);
    }

    function testFailSafeTransferFromToNonERC721RecipientWithData(uint256 id, bytes calldata data) public {
        token.plug(address(this), id);

        token.safeTransferFrom(address(this), address(new NonERC721Recipient()), id, data);
    }

    function testFailSafeTransferFromToRevertingERC721Recipient(uint256 id) public {
        token.plug(address(this), id);

        token.safeTransferFrom(address(this), address(new RevertingERC721Recipient()), id);
    }

    function testFailSafeTransferFromToRevertingERC721RecipientWithData(uint256 id, bytes calldata data) public {
        token.plug(address(this), id);

        token.safeTransferFrom(address(this), address(new RevertingERC721Recipient()), id, data);
    }

    function testFailSafeTransferFromToERC721RecipientWithWrongReturnData(uint256 id) public {
        token.plug(address(this), id);

        token.safeTransferFrom(address(this), address(new WrongReturnDataERC721Recipient()), id);
    }

    function testFailSafeTransferFromToERC721RecipientWithWrongReturnDataWithData(uint256 id, bytes calldata data)
        public
    {
        token.plug(address(this), id);

        token.safeTransferFrom(address(this), address(new WrongReturnDataERC721Recipient()), id, data);
    }

    function testOwnerOfUnminted(uint256 id) public {
        // this is different form the solmate implementation
        assertEq(token.ownerOf(id), address(0));
    }
}