// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IHypERC20 is IERC20 {
  /**
    * @notice Transfers tokens to the specified recipient on a remote chain
    * @param _destination The domain ID of the destination chain
    * @param _recipient The address of the recipient, encoded as bytes32
    * @param _amount The amount of tokens to transfer
    */
  function transferRemote(
    uint32 _destination,
    bytes32 _recipient,
    uint256 _amount
  ) external payable;
}


contract LockNDrop {
  mapping (uint32 => address) public chainRouter;

  function crossChainTransfer(bytes memory data) public {
    (address receiver, uint256 amount, uint32 chainId) = abi.decode(data, (address, uint256, uint32));
    if (chainRouter[chainId] != address(0)) {
      IHypERC20(chainRouter[chainId]).transferRemote(chainId, bytes32(bytes20(uint160(receiver))), amount);
    }
  }

  function addRouter(uint32 chainId, address router) public {
    chainRouter[chainId] = router;
  }
}