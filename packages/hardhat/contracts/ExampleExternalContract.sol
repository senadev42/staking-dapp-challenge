// SPDX-License-Identifier: MIT
pragma solidity 0.8.4; //Do not change the solidity version as it negativly impacts submission grading

contract ExampleExternalContract {
    //is it completed? this is also a public function

    //a function to flip this from who-knows to yes
    function complete() public payable {}

    function returnfunds(address payable _to) public payable {
        (bool sent, bytes memory data) = _to.call{value: address(this).balance}(
            ""
        );
        require(sent, "Failed to send Ether");
    }
}
