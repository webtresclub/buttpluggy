const {keccak256, encodePacked} = require('viem');


let n = 441000n;

const USER ='0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D';
const CURRENT_SALT ='0x398fa36d091cdce6844aaf66e84de736e0849a052fd5fdb8b5c60f13c0506b5a';

while(true) {
  const message = encodePacked(['address', 'bytes32', 'uint256'], [USER, CURRENT_SALT, n])
  const result = keccak256(message);
  // demo para una dificultad de 5 ceros
  if(result.slice(2,7) == '00000') {
    console.log(message);

    console.log("seed:", n);
    console.log("hash:", result);
    break;
  };
  n += 1n;
}