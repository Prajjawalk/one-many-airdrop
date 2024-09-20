// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseHook} from "v4-periphery/src/base/hooks/BaseHook.sol";

import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "v4-core/src/types/BeforeSwapDelta.sol";
import "@uniswap/v4-core/contracts/interfaces/IUniswapV4Pool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MultiDrop is BaseHook {
    using PoolIdLibrary for PoolKey;

    // NOTE: ---------------------------------------------------------
    // state variables should typically be unique to a pool
    // a single hook contract should be able to service multiple pools
    // ---------------------------------------------------------------

    // mapping(PoolId => uint256 count) public beforeSwapCount;
    // mapping(PoolId => uint256 count) public afterSwapCount;

    // mapping(PoolId => uint256 count) public beforeAddLiquidityCount;
    // mapping(PoolId => uint256 count) public beforeRemoveLiquidityCount;
    // Mapping to store tokenB balances before the swap for each user
    mapping(address => uint256) private preSwapBalances;

    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: true,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: true,
            afterRemoveLiquidity: false,
            beforeSwap: true,
            afterSwap: true,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    // -----------------------------------------------
    // NOTE: see IHooks.sol for function documentation
    // -----------------------------------------------

    function beforeSwap(address sender, PoolKey calldata key, IPoolManager.SwapParams calldata swapParams, bytes calldata hookData)
        external
        override
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        // beforeSwapCount[key.toId()]++;
        (bool isOneMany, address[] receivers) = abi.decode(hookData, (bool, address[]));
        if(isOneMany) {
          
          require(receivers.length > 0);
          
          if(swapParams.zeroForOne) {
            address token1 = key.currency1;
            preSwapBalances[sender] = IERC20(token1).balanceOf(sender);
          } else {
            address token0 = key.currency0;
            preSwapBalances[sender] = IERC20(token0).balanceOf(sender);
          }
        }

        
        return (BaseHook.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }

    function afterSwap(address, PoolKey calldata key, IPoolManager.SwapParams calldata, BalanceDelta, bytes calldata hookData)
        external
        override
        returns (bytes4, int128)
    {
        // afterSwapCount[key.toId()]++;
        (bool isOneMany, address[] receivers) = abi.decode(hookData, (bool, address[]));
        uint256 amount;
        if(isOneMany) {
          // beforeSwapCount[key.toId()]++;
          if(swapParams.zeroForOne) {
            address token1 = key.currency1;
            uint256 postSwapBalance = IERC20(token1).balanceOf(sender);
            amount = postSwapBalance - preSwapBalances[sender];
            uint amountPerAddress = amount/receivers.length;

            for (uint i = 0; i < receivers.length; i++) {
              IERC20(token1).transferFrom(sender, receivers[i]);
            }
          } else {
            address token0 = key.currency0;
            uint256 postSwapBalance = IERC20(token0).balanceOf(sender);
            amount = postSwapBalance - preSwapBalances[sender];

            uint amountPerAddress = amount/receivers.length;

            for (uint i = 0; i < receivers.length; i++) {
              IERC20(token1).transferFrom(sender, receivers[i]);
            }
          }
        }
        return (BaseHook.afterSwap.selector, 0);
    }

    function beforeAddLiquidity(
        address,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata,
        bytes calldata
    ) external override returns (bytes4) {
        beforeAddLiquidityCount[key.toId()]++;
        return BaseHook.beforeAddLiquidity.selector;
    }

    function beforeRemoveLiquidity(
        address,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata,
        bytes calldata
    ) external override returns (bytes4) {
        beforeRemoveLiquidityCount[key.toId()]++;
        return BaseHook.beforeRemoveLiquidity.selector;
    }
}
