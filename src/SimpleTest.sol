// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// function sign(signer, contract, x, deadline) {
//     const msgParams = JSON.stringify(
//     {
//         types: {
//             EIP712Domain:[
//               {name:"name",type:"string"},
//               {name:"version",type:"string"},
//               {name:"chainId",type:"uint256"},
//               {name:"verifyingContract",type:"address"}
//             ],
//             set:[
//               {name:"sender",type:"address"},
//               {name:"x",type:"uint"},
//               {name:"deadline", type:"uint"}
//             ]
//           },
//           //make sure to replace verifyingContract with address of deployed contract
//           primaryType:"set",
//           domain:{name: "SetTest", version:"1", chainId: '0x5',verifyingContract: contract},
//           message:{
//             sender: signer,
//             x: x,
//             deadline: deadline
//           }
//       })
//     const from = signer
//     const params = [from, msgParams]
//     const method = 'eth_signTypedData_v3'
//     web3.currentProvider.sendAsync({method, params, from} , async function (err, result) {
//         if (err) return console.dir(err)
//         if (result.error) {
//             alert(result.error.message)
//         }
//         if (result.error) return console.error('ERROR', result)
//         console.log('TYPED SIGNED:' + JSON.stringify(result.result))
//         const signature = result.result.substring(2);
//         const r = "0x" + signature.substring(0, 64);
//         const s = "0x" + signature.substring(64, 128);
//         const v = parseInt(signature.substring(128, 130), 16);
//         console.log("r:", r);
//         console.log("s:", s);
//         console.log("v:", v);
//     })
    
// }
contract SimpleStorage {
  uint storedData;
  bytes32 public DOMAIN_SEPARATOR = keccak256(
        abi.encode(
            keccak256(
                "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
            ),
            keccak256(bytes("SetTest")),
            keccak256(bytes("1")),
            5,
            address(this)
        )
    );  

  function set(uint x) internal {
    storedData = x;
  }

  function get() public view returns (uint) {
    return storedData;
  }

  function executeSetIfSignatureMatch(
    uint8 v,
    bytes32 r,
    bytes32 s,
    address sender,
    uint256 deadline,
    uint x
  ) external {
    require(block.timestamp < deadline, "Signed transaction expired");

    uint chainId;
    assembly {
      chainId := chainid()
    }


    bytes32 hashStruct = keccak256(
      abi.encode(
          keccak256("set(address sender,uint x,uint deadline)"),
          sender,
          x,
          deadline
        )
    );

    bytes32 hash = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hashStruct));
    address signer = ecrecover(hash, v, r, s);
    require(signer == sender, "MyFunction: invalid signature");
    require(signer != address(0), "ECDSA: invalid signature");

    set(x);
  }
}