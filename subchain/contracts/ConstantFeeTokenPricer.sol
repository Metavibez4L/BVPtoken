// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
 * @title ConstantFeeTokenPricer
 * @dev Returns a fixed token amount for any gas usage.
 */
contract ConstantFeeTokenPricer {
    address public immutable feeToken;
    uint256 public immutable feeAmount;

    /**
     * @param _feeToken   ERC-20 token used to pay fees
     * @param _feeAmount  Fixed amount of tokens to pay per L1 gas unit
     */
    constructor(address _feeToken, uint256 _feeAmount) {
        feeToken  = _feeToken;
        feeAmount = _feeAmount;
    }

    /**
     * @notice Always returns the same feeAmount
     * @param gasUsed         The gas used (ignored)
     * @param refundRecipient The recipient of any refund (ignored)
     * @return The fixed token fee
     */
    function tokenGasPrice(
        uint256 gasUsed,
        address refundRecipient
    ) external view returns (uint256) {
        // gasUsed and refundRecipient are intentionally unused
        return feeAmount;
    }
}
