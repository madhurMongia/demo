pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../src/interaction/SwaprSavingsXDaiRouter.sol";

/// @title Quoter Interface
/// @notice Supports quoting the calculated amounts from exact input or exact output swaps
/// @dev These functions are not marked view because they rely on calling non-view functions and reverting
/// to compute the result. They are also not gas efficient and should not be called on-chain.
/// Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-periphery
interface IQuoter {
    /// @notice Returns the amount out received for a given exact input swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair
    /// @param amountIn The amount of the first token to swap
    /// @return amountOut The amount of the last token that would be received
    function quoteExactInput(
        bytes memory path,
        uint256 amountIn
    ) external returns (uint256 amountOut, uint16[] memory fees);

    /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param amountIn The desired input amount
    /// @param limitSqrtPrice The price limit of the pool that cannot be exceeded by the swap
    /// @return amountOut The amount of `tokenOut` that would be received
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint160 limitSqrtPrice
    ) external returns (uint256 amountOut, uint16 fee);

    /// @notice Returns the amount in required for a given exact output swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair. Path must be provided in reverse order
    /// @param amountOut The amount of the last token to receive
    /// @return amountIn The amount of first token required to be paid
    function quoteExactOutput(
        bytes memory path,
        uint256 amountOut
    ) external returns (uint256 amountIn, uint16[] memory fees);

    /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param amountOut The desired output amount
    /// @param limitSqrtPrice The price limit of the pool that cannot be exceeded by the swap
    /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint256 amountOut,
        uint160 limitSqrtPrice
    ) external returns (uint256 amountIn, uint16 fee);
}

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Algebra
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-periphery
interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 limitSqrtPrice;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(
        ExactInputParams calldata params
    ) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 limitSqrtPrice;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(
        ExactOutputSingleParams calldata params
    ) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(
        ExactOutputParams calldata params
    ) external payable returns (uint256 amountIn);

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @dev Unlike standard swaps, handles transferring from user before the actual swap.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingleSupportingFeeOnTransferTokens(
        ExactInputSingleParams calldata params
    ) external returns (uint256 amountOut);
}

contract SwaprSavingsXDaiRouterTest is Test {
    SwaprSavingsXDaiRouter swaprSXDaiRouter;

    // gnosis addresses
    address internal xDAI = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE); // dummy xDAI address
    IERC20 internal outcomeToken =
        IERC20(0x1647EEDAd5cd2656614B69b21c6342B6B60D2231); // outcome address
    IERC4626 internal sDAI =
        IERC4626(0xaf204776c7245bF4147c2612BF6e5972Ee483701); // sDAI address
    IERC20 public constant wxDAI =
        IERC20(0xe91D153E0b41518A2Ce8Dd3D7944Fa863463a97d); // wxDAI address

    ISwapRouter public constant swaprRouter =
        ISwapRouter(0xfFB643E73f280B97809A8b41f7232AB401a04ee1); // Swapr Router address
    IQuoter public constant swaprQuoter =
        IQuoter(0xcBaD9FDf0D2814659Eb26f600EFDeAF005Eda0F7); // Swapr Quoter address

    uint256 forkSeer;
    uint256 forkSwapr;

    function setUp() public {
        forkSeer = vm.createFork("https://rpc.ankr.com/gnosis", 35257225);
        forkSwapr = vm.createFork("https://rpc.ankr.com/gnosis", 35257225);

        swaprSXDaiRouter = new SwaprSavingsXDaiRouter();
        vm.makePersistent(address(swaprSXDaiRouter));
    }

    // Helper Functions

    function swapExactInputSetup(address tokenIn, uint256 amountIn) internal {
        if (tokenIn != xDAI) {
            deal(tokenIn, address(this), amountIn);
        }
    }

    function swaprSXDaiRouterExactInputSingle(
        uint256 amountIn,
        address tokenIn,
        address tokenOut
    ) internal returns (uint256 quotedAmountOut, uint256 amountOut) {
        ISingleSwapRouter.ExactInputSingleParams
            memory inputParams = ISingleSwapRouter.ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                recipient: address(this),
                deadline: block.timestamp + 120,
                amountIn: amountIn,
                amountOutMinimum: 0,
                limitSqrtPrice: 0
            });

        (quotedAmountOut, ) = swaprSXDaiRouter.quoteExactInputSingle(
            tokenIn,
            tokenOut,
            amountIn,
            0
        );

        if (tokenIn == xDAI) {
            return (
                quotedAmountOut,
                swaprSXDaiRouter.exactInputSingle{value: amountIn}(inputParams)
            );
        } else {
            IERC20(tokenIn).approve(address(swaprSXDaiRouter), amountIn);
            return (
                quotedAmountOut,
                swaprSXDaiRouter.exactInputSingle(inputParams)
            );
        }
    }

    function swapExactOutputSetup(
        address tokenIn,
        uint256 amountInMaximum
    ) internal {
        if (tokenIn == xDAI) {
            deal(address(this), amountInMaximum);
        } else {
            deal(tokenIn, address(this), amountInMaximum);
        }
    }

    function swaprSXDaiRouterExactOutputSingle(
        uint256 amountOut,
        uint256 amountInMaximum,
        address tokenIn,
        address tokenOut
    ) internal returns (uint256 quotedAmountIn, uint256 amountIn) {
        ISingleSwapRouter.ExactOutputSingleParams
            memory outputParams = ISingleSwapRouter.ExactOutputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: 0,
                recipient: address(this),
                deadline: block.timestamp + 120,
                amountOut: amountOut,
                amountInMaximum: amountInMaximum,
                limitSqrtPrice: 0
            });

        (quotedAmountIn, ) = swaprSXDaiRouter.quoteExactOutputSingle(
            tokenIn,
            tokenOut,
            amountOut,
            0
        );
        if (tokenIn == xDAI) {
            return (
                quotedAmountIn,
                swaprSXDaiRouter.exactOutputSingle{value: amountInMaximum}(
                    outputParams
                )
            );
        } else {
            IERC20(tokenIn).approve(address(swaprSXDaiRouter), amountInMaximum);
            return (
                quotedAmountIn,
                swaprSXDaiRouter.exactOutputSingle(outputParams)
            );
        }
    }

    function swaprRouterExactInput(
        uint256 amountIn,
        address tokenIn,
        address tokenOut
    ) internal returns (uint256 quotedAmountOut, uint256 amountOut) {
        if (tokenIn == address(sDAI) || tokenOut == address(sDAI)) {
            ISwapRouter.ExactInputSingleParams
                memory inputSingleParams = ISwapRouter.ExactInputSingleParams({
                    tokenIn: tokenIn,
                    tokenOut: tokenOut,
                    recipient: address(this),
                    deadline: block.timestamp + 120,
                    amountIn: amountIn,
                    amountOutMinimum: 0,
                    limitSqrtPrice: 0
                });
            IERC20(tokenIn).approve(address(swaprRouter), amountIn);
            (quotedAmountOut, ) = swaprQuoter.quoteExactInputSingle(
                tokenIn,
                tokenOut,
                amountIn,
                0
            );
            return (
                quotedAmountOut,
                swaprRouter.exactInputSingle(inputSingleParams)
            );
        }

        ISwapRouter.ExactInputParams memory inputParams = ISwapRouter
            .ExactInputParams({
                path: abi.encodePacked(tokenIn, sDAI, tokenOut),
                recipient: address(this),
                deadline: block.timestamp + 120,
                amountIn: amountIn,
                amountOutMinimum: 0
            });
        IERC20(tokenIn).approve(address(swaprRouter), amountIn);
        (quotedAmountOut, ) = swaprQuoter.quoteExactInput(
            abi.encodePacked(tokenIn, sDAI, tokenOut),
            amountIn
        );
        return (quotedAmountOut, swaprRouter.exactInput(inputParams));
    }

    function swaprRouterExactOutput(
        uint256 amountOut,
        uint256 amountInMaximum,
        address tokenIn,
        address tokenOut
    ) internal returns (uint256 quotedAmountIn, uint256 amountIn) {
        if (tokenIn == address(sDAI) || tokenOut == address(sDAI)) {
            ISwapRouter.ExactOutputSingleParams
                memory outputSingleParams = ISwapRouter
                    .ExactOutputSingleParams({
                        tokenIn: tokenIn,
                        tokenOut: tokenOut,
                        fee: 0,
                        recipient: address(this),
                        deadline: block.timestamp + 120,
                        amountOut: amountOut,
                        amountInMaximum: amountInMaximum,
                        limitSqrtPrice: 0
                    });
            IERC20(tokenIn).approve(address(swaprRouter), amountInMaximum);
            (quotedAmountIn, ) = swaprQuoter.quoteExactOutputSingle(
                tokenIn,
                tokenOut,
                amountOut,
                0
            );
            return (
                quotedAmountIn,
                swaprRouter.exactOutputSingle(outputSingleParams)
            );
        }

        ISwapRouter.ExactOutputParams memory outputParams = ISwapRouter
            .ExactOutputParams({
                path: abi.encodePacked(tokenOut, sDAI, tokenIn),
                recipient: address(this),
                deadline: block.timestamp + 120,
                amountOut: amountOut,
                amountInMaximum: amountInMaximum
            });
        IERC20(tokenIn).approve(address(swaprRouter), amountInMaximum);
        (quotedAmountIn, ) = swaprQuoter.quoteExactOutput(
            abi.encodePacked(tokenOut, sDAI, tokenIn),
            amountOut
        );
        return (quotedAmountIn, swaprRouter.exactOutput(outputParams));
    }

    function getBalance(
        IERC20 token,
        address owner
    ) internal returns (uint256) {
        if (address(token) == xDAI) {
            return address(owner).balance;
        }

        return token.balanceOf(owner);
    }

    struct TokenBalances {
        uint256 tokenIn;
        uint256 tokenOut;
    }

    function getBalances(
        IERC20 tokenIn,
        IERC20 tokenOut,
        address owner
    ) internal returns (TokenBalances memory) {
        return
            TokenBalances(
                getBalance(tokenIn, owner),
                getBalance(tokenOut, owner)
            );
    }

    function getBalancesChange(
        IERC20 tokenIn,
        uint256 tokenInInitialBalance,
        IERC20 tokenOut,
        uint256 tokenOutInitialBalance,
        address owner
    ) internal returns (TokenBalances memory) {
        return
            TokenBalances(
                tokenInInitialBalance - getBalance(tokenIn, owner),
                getBalance(tokenOut, owner) - tokenOutInitialBalance
            );
    }

    // Test Exact Input

    function assertSwapExactInputSingle(
        uint256 amountIn,
        IERC20 tokenIn,
        IERC20 tokenOut
    ) internal {
        // swap using seer router
        vm.selectFork(forkSeer);
        swapExactInputSetup(address(tokenIn), amountIn);
        TokenBalances memory initialBalances1 = getBalances(
            tokenIn,
            tokenOut,
            address(this)
        );
        (
            uint256 quotedAmountOut1,
            uint256 amountOut1
        ) = swaprSXDaiRouterExactInputSingle(
                amountIn,
                address(tokenIn),
                address(tokenOut)
            );
        TokenBalances memory balancesChange1 = getBalancesChange(
            tokenIn,
            initialBalances1.tokenIn,
            tokenOut,
            initialBalances1.tokenOut,
            address(this)
        );

        assertEq(address(swaprSXDaiRouter).balance, 0, "Router native balance");
        assertEq(
            getBalance(tokenIn, address(swaprSXDaiRouter)),
            0,
            "Router tokenIn balance"
        );
        assertEq(
            getBalance(tokenOut, address(swaprSXDaiRouter)),
            0,
            "Router tokenOut balance"
        );

        // swap using swapr router
        vm.selectFork(forkSwapr);
        IERC20 swaprTokenIn = address(tokenIn) == xDAI ? wxDAI : tokenIn;
        IERC20 swaprTokenOut = address(tokenOut) == xDAI ? wxDAI : tokenOut;

        swapExactInputSetup(address(swaprTokenIn), amountIn);
        TokenBalances memory initialBalances2 = getBalances(
            swaprTokenIn,
            swaprTokenOut,
            address(this)
        );
        (uint256 quotedAmountOut2, uint256 amountOut2) = swaprRouterExactInput(
            amountIn,
            address(swaprTokenIn),
            address(swaprTokenOut)
        );
        TokenBalances memory balancesChange2 = getBalancesChange(
            swaprTokenIn,
            initialBalances2.tokenIn,
            swaprTokenOut,
            initialBalances2.tokenOut,
            address(this)
        );

        assertEq(
            balancesChange1.tokenIn,
            amountIn,
            "Assert spent all tokenIn 1"
        );
        assertEq(
            balancesChange2.tokenIn,
            amountIn,
            "Assert spent all tokenIn 2"
        );

        assertEq(
            quotedAmountOut1,
            amountOut1,
            "Assert same quote and amountOut1"
        );
        assertEq(
            quotedAmountOut2,
            amountOut2,
            "Assert same quote and amountOut2"
        );

        if (
            address(tokenIn) == address(sDAI) ||
            address(tokenOut) == address(sDAI)
        ) {
            // a sDAI<>OUTCOME_TOKEN swap produce the same output in both routers
            assertEq(
                quotedAmountOut1,
                quotedAmountOut2,
                "Assert same quote out"
            );
            assertEq(amountOut1, amountOut2, "Assert amountOut");
            assertEq(balancesChange1.tokenOut, balancesChange2.tokenOut);
        } else {
            // seer router should have more tokens because it has less slippage
            assertGt(
                quotedAmountOut1,
                quotedAmountOut2,
                "Assert better quote out"
            );
            assertGt(amountOut1, amountOut2, "Assert amountOut");
            assertGt(
                balancesChange1.tokenOut,
                balancesChange2.tokenOut,
                "Assert tokenOut balances"
            );
        }
    }

    function test_exactInputSingle_TokenIn_wxDai() external {
        // swap wxDAI->OUTCOME_TOKEN
        uint256 amountIn = 2 ether;

        assertSwapExactInputSingle(amountIn, wxDAI, outcomeToken);
    }

    function test_exactInputSingle_TokenIn_sDai() external {
        // swap sDAI->OUTCOME_TOKEN
        uint256 amountIn = 2 ether;

        assertSwapExactInputSingle(amountIn, sDAI, outcomeToken);
    }

    function test_exactInputSingle_TokenIn_xDai() external {
        // swap xDAI->OUTCOME_TOKEN
        uint256 amountIn = 2 ether;

        assertSwapExactInputSingle(amountIn, IERC20(xDAI), outcomeToken);
    }

    function test_exactInputSingle_TokenOut_wxDai() external {
        // swap OUTCOME_TOKEN->wxDAI
        uint256 amountIn = 2 ether;

        assertSwapExactInputSingle(amountIn, outcomeToken, wxDAI);
    }

    function test_exactInputSingle_TokenOut_sDai() external {
        // swap OUTCOME_TOKEN->sDAI
        uint256 amountIn = 2 ether;

        assertSwapExactInputSingle(amountIn, outcomeToken, sDAI);
    }

    function test_exactInputSingle_TokenOut_xDai() external {
        // swap OUTCOME_TOKEN->xDAI
        uint256 amountIn = 2 ether;

        assertSwapExactInputSingle(amountIn, outcomeToken, IERC20(xDAI));
    }

    // Test Exact Output

    function assertSwapExactOutputSingle(
        uint256 amountInMaximum,
        uint256 amountOut,
        IERC20 tokenIn,
        IERC20 tokenOut
    ) internal {
        // swap using seer router
        vm.selectFork(forkSeer);
        swapExactOutputSetup(address(tokenIn), amountInMaximum);
        TokenBalances memory initialBalances1 = getBalances(
            tokenIn,
            tokenOut,
            address(this)
        );
        (
            uint256 quotedAmountIn1,
            uint256 amountIn1
        ) = swaprSXDaiRouterExactOutputSingle(
                amountOut,
                amountInMaximum,
                address(tokenIn),
                address(tokenOut)
            );
        TokenBalances memory balancesChange1 = getBalancesChange(
            tokenIn,
            initialBalances1.tokenIn,
            tokenOut,
            initialBalances1.tokenOut,
            address(this)
        );

        assertEq(address(swaprSXDaiRouter).balance, 0, "Router native balance");
        assertEq(
            getBalance(tokenIn, address(swaprSXDaiRouter)),
            0,
            "Router tokenIn balance"
        );
        assertEq(
            getBalance(tokenOut, address(swaprSXDaiRouter)),
            0,
            "Router tokenOut balance"
        );

        // swap using swapr router
        vm.selectFork(forkSwapr);
        IERC20 swaprTokenIn = address(tokenIn) == xDAI ? wxDAI : tokenIn;
        IERC20 swaprTokenOut = address(tokenOut) == xDAI ? wxDAI : tokenOut;

        swapExactInputSetup(address(swaprTokenIn), amountInMaximum);
        TokenBalances memory initialBalances2 = getBalances(
            swaprTokenIn,
            swaprTokenOut,
            address(this)
        );
        (uint256 quotedAmountIn2, uint256 amountIn2) = swaprRouterExactOutput(
            amountOut,
            amountInMaximum,
            address(swaprTokenIn),
            address(swaprTokenOut)
        );
        TokenBalances memory balancesChange2 = getBalancesChange(
            swaprTokenIn,
            initialBalances2.tokenIn,
            swaprTokenOut,
            initialBalances2.tokenOut,
            address(this)
        );

        // we allow a small difference because of the intermediate sDAI.deposit(amountInMaximum)
        assertApproxEqAbs(
            quotedAmountIn1,
            amountIn1,
            10,
            "Assert same quote and amountIn1"
        );
        assertEq(quotedAmountIn2, amountIn2, "Assert same quote and amountIn2");

        if (
            address(tokenIn) == address(sDAI) ||
            address(tokenOut) == address(sDAI)
        ) {
            // a sDAI<>OUTCOME_TOKEN swap produce the same output in both routers
            assertEq(quotedAmountIn1, quotedAmountIn2, "Assert same quote in");
            assertEq(amountIn1, amountIn2, "Assert amountIn");
            assertEq(
                balancesChange1.tokenIn,
                balancesChange2.tokenIn,
                "Assert same tokenIn change"
            );
            assertEq(
                balancesChange1.tokenOut,
                balancesChange2.tokenOut,
                "Assert same tokenOut change"
            );
        } else {
            assertLt(
                quotedAmountIn1,
                quotedAmountIn2,
                "Assert better quote in"
            );
            assertLt(amountIn1, amountIn2, "Assert amountIn");
            // seer router should spend less tokens
            assertLt(
                balancesChange1.tokenIn,
                balancesChange2.tokenIn,
                "Assert tokenIn balances"
            );
            // we allow a small difference because of the intermediate sDAI.deposit(amountInMaximum)
            assertApproxEqAbs(
                balancesChange1.tokenOut,
                balancesChange2.tokenOut,
                10,
                "Assert tokenOut balances"
            );
        }
    }

    function test_exactOutputSingle_TokenIn_wxDai() external {
        // swap wxDAI->OUTCOME_TOKEN
        uint256 amountOut = 0.5 ether;
        uint256 amountInMaximum = 2 ether;

        assertSwapExactOutputSingle(
            amountInMaximum,
            amountOut,
            wxDAI,
            outcomeToken
        );
    }

    function test_exactOutputSingle_TokenIn_sDai() external {
        // swap sDAI->OUTCOME_TOKEN
        uint256 amountOut = 0.5 ether;
        uint256 amountInMaximum = 2 ether;

        assertSwapExactOutputSingle(
            amountInMaximum,
            amountOut,
            sDAI,
            outcomeToken
        );
    }

    function test_exactOutputSingle_TokenIn_xDai() external {
        // swap xDAI->OUTCOME_TOKEN
        uint256 amountOut = 0.5 ether;
        uint256 amountInMaximum = 2 ether;

        assertSwapExactOutputSingle(
            amountInMaximum,
            amountOut,
            IERC20(xDAI),
            outcomeToken
        );
    }

    function test_exactOutputSingle_TokenOut_wxDai() external {
        // swap OUTCOME_TOKEN->wxDAI
        uint256 amountOut = 0.8 ether;
        uint256 amountInMaximum = 3 ether;

        assertSwapExactOutputSingle(
            amountInMaximum,
            amountOut,
            outcomeToken,
            wxDAI
        );
    }

    function test_exactOutputSingle_TokenOut_sDai() external {
        // swap OUTCOME_TOKEN->sDAI
        uint256 amountOut = 0.8 ether;
        uint256 amountInMaximum = 3 ether;

        assertSwapExactOutputSingle(
            amountInMaximum,
            amountOut,
            outcomeToken,
            sDAI
        );
    }

    function test_exactOutputSingle_TokenOut_xDai() external {
        // swap OUTCOME_TOKEN->xDAI
        uint256 amountOut = 0.5 ether;
        uint256 amountInMaximum = 3 ether;

        assertSwapExactOutputSingle(
            amountInMaximum,
            amountOut,
            outcomeToken,
            IERC20(xDAI)
        );
    }

    receive() external payable {}
}