// Fundamental coding ideas, ERC20 coding developed from [1][2], and key academic papers included [3]–[5]
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

// With the incorporation of SafeMath functionality into Solidity 0.8.0 and later versions, 
// importing the SafeMath library is no longer necessary for basic arithmetic operations. 
// The compiler itself applies the necessary checks to prevent arithmetic overflows and underflows.
// However, there can still be cases where importing the SafeMath library may provide additional benefits, 
// even in Solidity 0.8.0 and beyond, e.g., for legacy code, complex operations, code readability, 
// or community standards.  Nonetheless, this section can be commented out.

 library SafeMath {
    // Adds two numbers with overflow protection
    function add(uint256 x, uint256 y) public pure returns (uint256) {
        uint256 z = x + y;
        require(x < z, "Addition overflow");
        return z;
    }

    // Subtracts two numbers with underflow protection
    function subtract(uint256 x, uint256 y) public pure returns (uint256) {
        require(x >= y, "Subtraction underflow");
        return x - y;
    }

    // Multiplies two numbers with overflow protection
    function multiply(uint256 x, uint256 y) public pure returns (uint256) {
        if (x == 0) return 0;
        uint256 z = x * y;
        require(z / x == y, "Multiplication overflow");
        return z;
    }

    // Divides two numbers
    function divide(uint256 x, uint256 y) public pure returns (uint256) {
        uint256 z = x / y;
        return z;
    }   
}

contract Token {
    using SafeMath for uint256;

    mapping(address => uint256) accountBalances;
    address systemOperator;
    uint256 totalSupplyOfTokens_;

    event energyTransfer(address from, address to, uint256 value);
    event energyCheck(uint256 userID, address energyOwner, uint256 energyAmount, uint256 energyState, uint256 energyBidTime);
    event requestCheck(address _add, uint256 energyAmount);
    event requestBuyCheck(uint256 userID, uint256 Amount);
    event logGeneration(uint256 o);
    event transferResult(address from, address to, uint256 value, uint256 BalanceofSender, uint256 BalanceofReceiver);
    event roundStart(uint256 stime, uint256 etime);
    event UserRegistrationRemoved(address indexed userAddress);

modifier onlysystemOperator() {
    // Ensures that only the systemOperator can call the function
    require(msg.sender == systemOperator, "Only the systemOperator can call this function.");
    _;
}

    // Returns the balance of tokens for a given address
    function balanceOf(address _energyOwner) public view returns (uint256 balance) {
        return accountBalances[_energyOwner];
    }

    // Returns the total supply of tokens
    function totalSupply() public view returns (uint256) {
        return totalSupplyOfTokens_;
    }

    // Transfers tokens from the caller to a specified address
    function transfer(address _transferTo, uint256 _transferValue) public returns (bool) {
        require(_transferTo != address(0), "Cannot transfer to the zero address");
        require(_transferValue <= accountBalances[msg.sender], "Insufficient balance");
        accountBalances[msg.sender] = accountBalances[msg.sender] - _transferValue;
        accountBalances[_transferTo] = accountBalances[_transferTo] + _transferValue;
        emit transferResult(msg.sender, _transferTo, _transferValue, accountBalances[msg.sender], accountBalances[_transferTo]);
        return true;
    }

    event Approval(address energyOwner, address spender, uint256 value);

    mapping(address => mapping(address => uint256)) internal allowed;

    // Transfers tokens from a specified address to another address.
    // Checks if the spender (System Operator in this code) is allowed to transfer
    // the specified amount of tokens from the 'from' address
function transferFrom(address _transferFrom, address _transferTo, uint256 _transferValue) public returns (bool) {
    require(_transferTo != address(0), "Invalid transfer address");
    require(_transferValue <= accountBalances[_transferFrom], "Insufficient balance");
    require(_transferValue <= allowed[_transferFrom][msg.sender], "Transfer amount exceeds allowance");

    accountBalances[_transferFrom] -= _transferValue;
    accountBalances[_transferTo] += _transferValue;
    allowed[_transferFrom][msg.sender] -= _transferValue;

    emit transferResult(_transferFrom, _transferTo, _transferValue, accountBalances[_transferFrom], accountBalances[_transferTo]);
    return true;
}

function approve(address _approvalSpender, uint256 _transferValue) public returns (bool) {
    // Allows `_approvalSpender` to transfer `_transferValue` tokens from the caller's address
    // For example, when the buyEnergy function calls the approve function, the _approvalSpender is the systemOperator
    // and the _transferValue is the _amount * maxiumumEnergyPrice
    // where _amount is the amount of Energy that was requested when the buyEnergy function was called
    allowed[msg.sender][_approvalSpender] = _transferValue;
    emit Approval(msg.sender, _approvalSpender, _transferValue);
    return true;
}

function allowance(address _energyOwner, address _approvalSpender) public view returns (uint256) {
    // Returns the amount of tokens that `_approvalSpender` is allowed to transfer on behalf of `_energyOwner`
    return allowed[_energyOwner][_approvalSpender];
}

function increaseApproval(address _approvalSpender, uint256 _approvalAddedValue) public returns (bool) {
    // Increases the amount of tokens that `_approvalSpender` is allowed to transfer from the caller's address
    allowed[msg.sender][_approvalSpender] = allowed[msg.sender][_approvalSpender]+(_approvalAddedValue);
    emit Approval(msg.sender, _approvalSpender, allowed[msg.sender][_approvalSpender]);
    return true;
}

function decreaseApproval(address _approvalSpender, uint256 _approvalSubtractedValue) public returns (bool) {
    // Decreases the amount of tokens that `_approvalSpender` is allowed to transfer from the caller's address
    uint256 previousApprovalValue = allowed[msg.sender][_approvalSpender];
    if (_approvalSubtractedValue > previousApprovalValue) {
        allowed[msg.sender][_approvalSpender] = 0;
    } else {
        allowed[msg.sender][_approvalSpender] = previousApprovalValue-(_approvalSubtractedValue);
    }
    emit Approval(msg.sender, _approvalSpender, allowed[msg.sender][_approvalSpender]);
    return true;
}

string public constant tokenName = "EnergyToken";
string public constant tokenSymbol = "POW";
uint8 public constant tokenDecimals = 18;
// The value 18 is a commonly used default for the tokenDecimals parameter in Ethereum-based smart contracts. 
// It represents the number of decimal places used for token balances and calculations. 
// In the Ethereum ecosystem, the ERC-20 token standard specifies 18 decimal places as the default. 
// This default allows for a high level of divisibility and precision when dealing with token amounts.
uint256 public constant initialTokenSupply = 10000000 * (10 ** uint256(tokenDecimals));

constructor() {
    // Initializes the EnergyToken contract
    totalSupplyOfTokens_ = initialTokenSupply;
    accountBalances[msg.sender] = initialTokenSupply;
    emit transferResult(address(0), msg.sender, initialTokenSupply, accountBalances[address(0)], accountBalances[msg.sender]);
    systemOperator = msg.sender;
    emit logGeneration(0);
}

// This maximum price limit ensures that the energy can only be bought at a price within the specified range, 
// preventing excessively high prices. // It serves as a safeguard against potential manipulation 
// or abuse of the buying process by imposing an upper limit on the price.
uint256 maximumEnergyPrice = 50;  
// 50 chosen as an arbitrary maximum price for energy units, 
// and can be amended as per system requirements.
uint256 totalSellAmount = 0;
uint256 totalBuyAmount = 0;

struct energyStruct {
    // Represents an energy struct with userID, owner, amount, state, and bid time
    uint256 userID;
    address energyOwner;
    uint256 energyAmount;
    uint256 energyState;
    uint256 energyBidTime;
}

mapping(address => uint256) addressIndex;
uint256 totalPeopleCount = 0;
energyStruct[][] energyArray;
energyStruct[] temporaryEnergyArray;

struct sellStruct {
    // Represents a sell request with owner and amount
    address sellOwner;
    uint256 sellAmount;
}

sellStruct[] sellArray;
uint256 sellIndex = 0;

struct buyStruct {
    // Represents a buy request with owner and amount
    address buyOwner;
    uint256 buyAmount;
}

buyStruct[] buyArray;
uint256 buyIndex = 0;
uint roundEndTimestamp;

    // New mapping to store userID corresponding to each user address
    mapping(address => uint256) addressToUserID;

// function to register users quickly during testing
function registerUsers(uint256 numberOfUsers) public onlysystemOperator {
    for (uint256 i = 0; i < numberOfUsers; i++) {
        address newUser = address(uint160(uint(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, i)))));
    // Registers a user by assigning an index, creating an initial energy struct, and updating the totalPeopleCount
        addressIndex[newUser] = totalPeopleCount;
        energyStruct memory initialEnergy = energyStruct(totalPeopleCount, newUser, 0, 0, block.timestamp);
        temporaryEnergyArray.push(initialEnergy);
        energyArray.push(temporaryEnergyArray);
    // Set the user's registration status to true
        isRegisteredUser[newUser] = true;
        emit energyCheck(
            energyArray[totalPeopleCount][0].userID,
            energyArray[totalPeopleCount][0].energyOwner,
            energyArray[totalPeopleCount][0].energyAmount,
            energyArray[totalPeopleCount][0].energyState,
            energyArray[totalPeopleCount][0].energyBidTime
        );  
        totalPeopleCount++;
        delete temporaryEnergyArray;
    // Make buyEnergy or sellEnergy requests on behalf of each user here
    // populate the userID for newly registered users
        userIDToAddress[totalPeopleCount - 1] = newUser;
    }
}

// The userRegistration function in the given code can currently be called by anyone who interacts with the token contract. 
// It does not currently have any access control modifiers or conditions that restrict its usage to specific addresses or roles.
// Therefore, any Ethereum address can call the userRegistration function to register as a user in the system.
// Ultimately, a version of access control may be beneficial.
// Furthermore, at this stage access rights can be assigned, such as consumer, generator or prosumer etc.
function userRegistration() public {
     // Registers a user by assigning an index, creating an initial energy struct, and updating the totalPeopleCount
    addressIndex[msg.sender] = totalPeopleCount;
    energyStruct memory initialEnergy = energyStruct(totalPeopleCount, msg.sender, 0, 0, block.timestamp); // Add userID to energyStruct.  Also, block.timestamp = 'now'.  
    temporaryEnergyArray.push(initialEnergy);
    energyArray.push(temporaryEnergyArray);

    // Set the user's registration status to true
    isRegisteredUser[msg.sender] = true;
    
    emit energyCheck(
        energyArray[totalPeopleCount][0].userID,
        energyArray[totalPeopleCount][0].energyOwner,
        energyArray[totalPeopleCount][0].energyAmount,
        energyArray[totalPeopleCount][0].energyState,
        energyArray[totalPeopleCount][0].energyBidTime
    );
    totalPeopleCount++;
    delete temporaryEnergyArray;

        // populate the userID for newly registered users
        addressToUserID[msg.sender] = totalPeopleCount - 1;
}

 // Function to get the list of registered users with their addresses
function getRegisteredUsers() public view returns (uint256[] memory, address[] memory) {
    uint256[] memory userIDs = new uint256[](totalPeopleCount);
    address[] memory energyOwners = new address[](totalPeopleCount);
    for (uint256 i = 0; i < totalPeopleCount; i++) {
        userIDs[i] = energyArray[i][0].userID;
        energyOwners[i] = energyArray[i][0].energyOwner;
    }
    return (userIDs, energyOwners);
}

// Amended from 'public' to 'internal' to avoid error message
mapping(address => bool) internal isRegisteredUser;   

// function added in to compensate for change from 'public to internal in preceding function
function getIsRegisteredUser(address userAddress) public view returns (bool) {  
        return isRegisteredUser[userAddress];
    }

    // Function to remove a registered user
    function removeUserRegistration(address _userAddress) public onlysystemOperator {
        // Check if the user is registered
        require(isRegisteredUser[_userAddress], "User is not registered.");

        // Get the user's index in the energyArray
        uint userIndex = addressIndex[_userAddress];

        // Delete the user's entry from the energyArray
        delete energyArray[userIndex];

        // Update the user's registration status
        isRegisteredUser[_userAddress] = false;

        // Emit an event to indicate the user's registration has been removed
        emit UserRegistrationRemoved(_userAddress);
    }

// Function to start a new round and set the round end time
function roundStartTime() public onlysystemOperator {
//    require(msg.sender == systemOperator, "Not the system operator");  // require function is redundant, given onlysystemOperator modifier
    uint roundDuration = 1 hours;
    roundEndTimestamp = roundDuration + block.timestamp; // block.timestamp is 'now'
    totalBuyAmount = 0;
    totalSellAmount = 0;
    emit roundStart(block.timestamp, roundEndTimestamp); // block.timestamp is 'now'
}

// Function to export energy from a specified energy owner
function energyExport(uint256 _userID, address _energyOwner, uint256 _amount) public onlysystemOperator {
//    require(msg.sender == systemOperator, "Not the system operator");  // require function is redundant, given onlysystemOperator modifier
    uint add = addressIndex[_energyOwner];
    energyStruct memory temporaryEnergy = energyStruct(_userID, _energyOwner, _amount, 1, block.timestamp); // block.timestamp is 'now'
    energyArray[add].push(temporaryEnergy);
    uint lastEnergyIndex = energyArray[add].length - 1;
    emit energyCheck(
        energyArray[add][lastEnergyIndex].userID, 
        energyArray[add][lastEnergyIndex].energyOwner, 
        energyArray[add][lastEnergyIndex].energyAmount, 
        energyArray[add][lastEnergyIndex].energyState, 
        energyArray[add][lastEnergyIndex].energyBidTime);
    delete temporaryEnergyArray;
    uint i = add;
    uint j;
    for (j = energyArray[i].length - 1; j > 1; j--) {
        if (energyArray[i][j].energyState == 1) {
            energyArray[i][1].energyAmount += energyArray[i][j].energyAmount;
            energyArray[i][1].energyBidTime = block.timestamp; // block.timestamp is 'now'
            delete energyArray[i][j];
        }
    }
    emit logGeneration(0);
}

// Function to make buyEnergy requests on behalf of registered users. 
// This function is used during testing and only by the authorised System Operator.
// This function does not work when using the ERC20 token, as ERC20 requires that the buyer actually does the call
// So if using, the code must be tweaked to incorporate.
function makeBuyEnergyRequests(uint256 numberOfRequests, uint256 amount, uint256 userID) public onlysystemOperator {
    for (uint256 i = 0; i < numberOfRequests; i++) {
        uint iIndex = userID;
        require(amount != 0, "Amount cannot be zero");
        require(amount * maximumEnergyPrice <= accountBalances[energyArray[iIndex][0].energyOwner], "Insufficient funds in account");

        // Set the allowance for the systemOperator to transfer tokens on behalf of the user
        approve(systemOperator, amount * maximumEnergyPrice);

        // decreaseApproval(energyArray[iIndex][0].energyOwner, amount * maximumEnergyPrice);  // 280723: removing this functionality during testing
        buyStruct memory buy = buyStruct(energyArray[iIndex][0].energyOwner, amount);
        buyArray.push(buy);
        buyIndex++;
        totalBuyAmount += amount;
        require(block.timestamp <= roundEndTimestamp, "Current time exceeds round end timestamp");
        emit requestBuyCheck(userID, amount);
    } 
}

// Add the mapping to relate userID to address
mapping(uint256 => address) public userIDToAddress;

// Function to make sellEnergy requests on behalf of registered users.
function makeSellEnergyRequests(uint256 numberOfRequests, uint256 amount, uint256 userID) public onlysystemOperator {
    for (uint256 i = 0; i < numberOfRequests; i++) {
        address userAddress = userIDToAddress[userID];
        require(isRegisteredUser[userAddress], "User is not registered.");

        for (uint j = energyArray[userID].length - 1; j > 1; j--) {
            if (energyArray[userID][j].energyState == 1) {
                energyArray[userID][1].energyAmount += energyArray[userID][j].energyAmount;
                energyArray[userID][1].energyBidTime = block.timestamp;
                delete energyArray[userID][j];
            }
        }
        require(energyArray[userID][1].energyAmount >= amount, "Insufficient energy to sell.");
        require(block.timestamp <= roundEndTimestamp, "Bid round has ended.");

        approve(systemOperator, amount * maximumEnergyPrice);

        energyStruct memory temporaryEnergy = energyStruct(userID, userAddress, amount, 2, block.timestamp);
        energyArray[userID].push(temporaryEnergy);
        energyArray[userID][1].energyAmount -= amount;
        sellStruct memory sell = sellStruct(userAddress, amount);
        sellArray.push(sell);
        emit requestCheck(userAddress, amount);
        sellIndex++;
        totalSellAmount += amount;
    }
}

// Function for a user to request selling energy
function sellEnergy(uint256 _amount) public {
    uint i = addressIndex[msg.sender];
    uint j;

    for(j = energyArray[i].length - 1; j > 1; j--){
        if(energyArray[i][j].energyState == 1){
            energyArray[i][1].energyAmount += energyArray[i][j].energyAmount;
            energyArray[i][1].energyBidTime = block.timestamp;
            delete energyArray[i][j];
        }
    }

    require(energyArray[i][1].energyAmount >= _amount, "Insufficient energy to sell.");
    require(block.timestamp <= roundEndTimestamp, "Bid round has ended.");

    energyStruct memory temporaryEnergy = energyStruct(i, msg.sender, _amount, 2, block.timestamp);
    energyArray[i].push(temporaryEnergy);
    energyArray[i][1].energyAmount -= _amount;

    sellStruct memory sell = sellStruct(msg.sender, _amount);
    sellArray.push(sell);

    emit requestCheck(msg.sender, _amount);

    sellIndex++;
    totalSellAmount += _amount;
}

// Function for a user to request buying energy
function buyEnergy(uint256 _amount) public {
    require(_amount != 0, "Amount cannot be zero");
    require(_amount * maximumEnergyPrice <= accountBalances[msg.sender], "Insufficient balance to make the purchase");
    require(block.timestamp <= roundEndTimestamp, "Purchase round has ended");
    
    decreaseApproval(systemOperator, accountBalances[msg.sender]);
    
    buyStruct memory buy = buyStruct(msg.sender, _amount);
    buyArray.push(buy);
    
    approve(systemOperator, _amount * maximumEnergyPrice);
    
    buyIndex++;
    totalBuyAmount += _amount;
     
    emit requestCheck(msg.sender, _amount);
}

// Struct for storing paired energy transactions
struct pairedEnergy {
    address energyProsumer;
    address energyConsumer;
    uint256 energyAmount;
    uint256 energyBidTime;
}

pairedEnergy[] energyPairs;

// Function to pair sell and buy requests based on energy amounts and perform energy transfers
// Called manually.
function pairing() public {
// Setting the roundEndTimestamp to the current timestamp.  This ensures the pairing process is performed only once per round. 
    roundEndTimestamp = block.timestamp;  

// Initialisation of variables, which are amended accordingly via pairing function operations    
    uint256 p = 1; // Percentage to adjust sell amounts based on totalSellAmount and totalBuyAmount
    uint256 sellIndex_trade = 0; 
    // Index for iterating over sellArray.  
    // When buy>sell amounts, a full sell happens and sellIndex_trade is incremented, 
    // and vice versa for when sell>buy amounts, a full buy happens and buyIndex_trade is incremented
    // When they are equal, both are incremented.
    uint256 buyIndex_trade = 0; // Index for iterating over buyArray
    uint i = 0; // Counter variable
    uint j = 0; // Counter variable
    
    // Section 1 of the pairing function
    // If totalSellAmount is greater than totalBuyAmount, adjust sell amounts proportionally
    //  This ensures the sell amounts are reduced proportionally to pair the available buy amounts.

    // The function enters loops to pair sell and buy requests 
    // and perform energy transfers until either the sellArray or buyArray is exhausted.

    if (totalSellAmount > totalBuyAmount) {
        p = totalBuyAmount * 100 / totalSellAmount;  // i.e. the percentage of total sells that have offers to be bought
        
// Adjust sell amounts in energyArray and update energyState
        for (i = 0; i < sellIndex; i++) {
            sellArray[i].sellAmount = sellArray[i].sellAmount * p / 100;  
// Reducing each sell amount to align with the confirmed proportion of buy offers relative to sell offers, i.e. p.  This facilitates the pairing system below.
            
            j = addressIndex[sellArray[i].sellOwner];

// Each row in the energyArray represents a user and contains multiple energyStruct elements. 
// The first element in each row (index 0) is used for storing general information about the user, 
// such as the userID, energyOwner, energyAmount, and energyState. 
// The subsequent elements in the row represent the specific energy transactions made by the user (energy available for sale or purchase).

// The energyArray is used to store information about the energy available for sale and purchase, 
// and it is used during the pairing process to identify compatible sell and buy offers.

// Taking an energyAmount figure (in proportion to p) away from the energyArray amount of the [j][length-1], 
// and then adding this to the energyAmount in the [j][1] position in the energyArray.    
// The amount taken away is then added to the energyAmount in the [j][energy[j].length - 1] position.
// This has the effect of keeping sum between the energy amounts of [j][1] and [j][...length-1] equal.
            energyArray[j][1].energyAmount += energyArray[j][energyArray[j].length - 1].energyAmount - energyArray[j][energyArray[j].length - 1].energyAmount * p / 100;
            energyArray[j][1].energyBidTime = block.timestamp;
            energyArray[j][energyArray[j].length - 1].energyAmount = energyArray[j][energyArray[j].length - 1].energyAmount * p / 100;
            energyArray[j][energyArray[j].length - 1].energyState = 3;
        }
        
        // Pair sell and buy energy requests and perform energy transfers
        // sellIndex_trade keeps track of the current position in the sellArray during the pairing process
        // buyIndex_trade is a variable used as an index for iterating over the buyArray during the pairing process.
        uint256 TemporarySellAmount = sellArray[sellIndex_trade].sellAmount;
        uint256 TemporaryBuyAmount = buyArray[buyIndex_trade].buyAmount;
        
        do {
            // Checks if the sell amount is greater than the buy amount.  
            // If it is, it means that the sell request can fulfill the entire buy request.
            if (TemporarySellAmount > TemporaryBuyAmount) {
                TemporarySellAmount -= TemporaryBuyAmount;  
                // This substraction indicates that a proportion of the of the sell request is paired, which gets stored in the paired energy array.
                
                // Store paired energy transaction in energyPairs array (which contains the sell owner, buy owner, paired energy amount and timestamp).
                pairedEnergy memory temporaryEnergyPaired = pairedEnergy(sellArray[sellIndex_trade].sellOwner, buyArray[buyIndex_trade].buyOwner, TemporaryBuyAmount, block.timestamp);
                energyPairs.push(temporaryEnergyPaired);  // store the trade (energy transfer) in the energyPairs array
                
                emit energyTransfer(sellArray[sellIndex_trade].sellOwner, buyArray[buyIndex_trade].buyOwner, TemporaryBuyAmount);  // emit an event.
                
                buyIndex_trade++;  // show that a trade has occurred by increasing the buy index by one.
                
                if (buyIndex_trade >= buyIndex) break;  //  This means all buy requests have been processed, so loop would break at this point if so.
                
                TemporaryBuyAmount = buyArray[buyIndex_trade].buyAmount;
            } else if (TemporarySellAmount < TemporaryBuyAmount) {  // TemporaryBuyAmount is not exhasusted.  Sell amount is smaller than the buy amount.
            // In this case, a partial pair is made.  Similar to the previous step, except the TemporarySellAmount is substracted from the TemporaryBuyAmount instead.
                TemporaryBuyAmount -= TemporarySellAmount;
                
                // Store the partial paired energy transaction in energyPairs array
                pairedEnergy memory temporaryEnergyPaired = pairedEnergy(sellArray[sellIndex_trade].sellOwner, buyArray[buyIndex_trade].buyOwner, TemporarySellAmount, block.timestamp);
                energyPairs.push(temporaryEnergyPaired);
                
                emit energyTransfer(sellArray[sellIndex_trade].sellOwner, buyArray[buyIndex_trade].buyOwner, TemporarySellAmount);  // emit an event.
                
                sellIndex_trade++;
                
                if (sellIndex_trade >= sellIndex) break;
                
                TemporarySellAmount = sellArray[sellIndex_trade].sellAmount;
            } else {
                // Store paired energy transaction in energyPairs array
                pairedEnergy memory temporaryEnergyPaired = pairedEnergy(sellArray[sellIndex_trade].sellOwner, buyArray[buyIndex_trade].buyOwner, TemporarySellAmount, block.timestamp);
                energyPairs.push(temporaryEnergyPaired);
                
                emit energyTransfer(sellArray[sellIndex_trade].sellOwner, buyArray[buyIndex_trade].buyOwner, TemporaryBuyAmount);
                
                sellIndex_trade++;
                buyIndex_trade++;
                
                if (buyIndex_trade >= buyIndex) break;
                if (sellIndex_trade >= sellIndex) break;
                
                TemporaryBuyAmount = buyArray[buyIndex_trade].buyAmount;
                TemporarySellAmount = sellArray[sellIndex_trade].sellAmount;
            }
        } while (true);
    } 

    // Section 2 of the pairing function
    // If totalSellAmount is less than totalBuyAmount, adjust buy amounts proportionally
    else if (totalSellAmount < totalBuyAmount) {
        p = totalSellAmount * 100 / totalBuyAmount;
        
        // Adjust buy amounts in buyArray
        for (i = 0; i < buyIndex; i++) {
            buyArray[i].buyAmount = buyArray[i].buyAmount * p / 100;
        }
        
        // Pair sell and buy energy requests and perform energy transfers
        uint256 TemporarySellAmount = sellArray[sellIndex_trade].sellAmount;
        uint256 TemporaryBuyAmount = buyArray[buyIndex_trade].buyAmount;
        
        do {
            if (TemporarySellAmount > TemporaryBuyAmount) {
                TemporarySellAmount -= TemporaryBuyAmount;
                
                // Store paired energy transaction in energyPairs array
                pairedEnergy memory temporaryEnergyPaired = pairedEnergy(sellArray[sellIndex_trade].sellOwner, buyArray[buyIndex_trade].buyOwner, TemporaryBuyAmount, block.timestamp);
                emit energyTransfer(sellArray[sellIndex_trade].sellOwner, buyArray[buyIndex_trade].buyOwner, TemporaryBuyAmount);
                
                energyPairs.push(temporaryEnergyPaired);
                
                buyIndex_trade++;
                
                if (buyIndex_trade >= buyIndex) break;
                
                TemporaryBuyAmount = buyArray[buyIndex_trade].buyAmount;
            } else if (TemporarySellAmount < TemporaryBuyAmount) {
                TemporaryBuyAmount -= TemporarySellAmount;
                
                // Store paired energy transaction in energyPairs array
                pairedEnergy memory temporaryEnergyPaired = pairedEnergy(sellArray[sellIndex_trade].sellOwner, buyArray[buyIndex_trade].buyOwner, TemporarySellAmount, block.timestamp);
                energyPairs.push(temporaryEnergyPaired);
                
                emit energyTransfer(sellArray[sellIndex_trade].sellOwner, buyArray[buyIndex_trade].buyOwner, TemporarySellAmount);
                
                sellIndex_trade++;
                
                if (sellIndex_trade >= sellIndex) break;
                
                TemporarySellAmount = sellArray[sellIndex_trade].sellAmount;
            } else {
                // Store paired energy transaction in energyPairs array
                pairedEnergy memory temporaryEnergyPaired = pairedEnergy(sellArray[sellIndex_trade].sellOwner, buyArray[buyIndex_trade].buyOwner, TemporarySellAmount, block.timestamp);
                energyPairs.push(temporaryEnergyPaired);
                
                emit energyTransfer(sellArray[sellIndex_trade].sellOwner, buyArray[buyIndex_trade].buyOwner, TemporaryBuyAmount);
                
                sellIndex_trade++;
                buyIndex_trade++;
                
                if (buyIndex_trade >= buyIndex) break;
                if (sellIndex_trade >= sellIndex) break;
                
                TemporaryBuyAmount = buyArray[buyIndex_trade].buyAmount;
                TemporarySellAmount = sellArray[sellIndex_trade].sellAmount;
            }
        } while (true);
    } 

    // Section 3 of the pairing function
    // If totalSellAmount is equal to totalBuyAmount
    else if (totalBuyAmount == totalSellAmount) {
        // Pair sell and buy energy requests and perform energy transfers
        uint256 TemporarySellAmount = sellArray[sellIndex_trade].sellAmount;
        uint256 TemporaryBuyAmount = buyArray[buyIndex_trade].buyAmount;
        
        do {
            if (TemporarySellAmount > TemporaryBuyAmount) {
                TemporarySellAmount -= TemporaryBuyAmount;
                
                // Store paired energy transaction in energyPairs array
                pairedEnergy memory temporaryEnergyPaired = pairedEnergy(sellArray[sellIndex_trade].sellOwner, buyArray[buyIndex_trade].buyOwner, TemporaryBuyAmount, block.timestamp);
                energyPairs.push(temporaryEnergyPaired);
                
                emit energyTransfer(sellArray[sellIndex_trade].sellOwner, buyArray[buyIndex_trade].buyOwner, TemporaryBuyAmount);
                
                buyIndex_trade++;
                
                if (buyIndex_trade >= buyIndex) break;
                
                TemporaryBuyAmount = buyArray[buyIndex_trade].buyAmount;
            } else if (TemporarySellAmount < TemporaryBuyAmount) {
                TemporaryBuyAmount -= TemporarySellAmount;
                
                // Store paired energy transaction in energyPairs array
                pairedEnergy memory temporaryEnergyPaired = pairedEnergy(sellArray[sellIndex_trade].sellOwner, buyArray[buyIndex_trade].buyOwner, TemporarySellAmount, block.timestamp);
                energyPairs.push(temporaryEnergyPaired);
                
                emit energyTransfer(sellArray[sellIndex_trade].sellOwner, buyArray[buyIndex_trade].buyOwner, TemporarySellAmount);
                
                sellIndex_trade++;
                
                if (sellIndex_trade > sellIndex) break;
                
                TemporarySellAmount = sellArray[sellIndex_trade].sellAmount;
            } else {
                // Store paired energy transaction in energyPairs array
                pairedEnergy memory temporaryEnergyPaired = pairedEnergy(sellArray[sellIndex_trade].sellOwner, buyArray[buyIndex_trade].buyOwner, TemporarySellAmount, block.timestamp);
                energyPairs.push(temporaryEnergyPaired);
                
                emit energyTransfer(sellArray[sellIndex_trade].sellOwner, buyArray[buyIndex_trade].buyOwner, TemporaryBuyAmount);
                
                sellIndex_trade++;
                buyIndex_trade++;
                
                if (buyIndex_trade >= buyIndex) break;
                if (sellIndex_trade >= sellIndex) break;
                
                TemporaryBuyAmount = buyArray[buyIndex_trade].buyAmount;
                TemporarySellAmount = sellArray[sellIndex_trade].sellAmount;
            }
        } while (true);
    }
    
    // Clean up energyArray by removing entries with zero amounts
    for (i = 0; i < totalPeopleCount; i++) {
        for (j = energyArray[i].length - 1; j > 1; j--) {
            if (energyArray[i][j].energyAmount == 0) delete energyArray[i][j];
        }
    }
    
    emit logGeneration(0);
}

// Function for finalising and executing trades based on the specified price
function finalisation(uint256 _price) public {
    uint256 price = _price;
    uint256 i;
    
    // Transfer energy and update energyArray for each paired energy transaction
    for (i = 0; i < energyPairs.length; i++) {
        // Retrieve the userID (i) for the consumer and prosumer
        uint userIDConsumer = addressIndex[energyPairs[i].energyConsumer];
        uint userIDProsumer = addressIndex[energyPairs[i].energyProsumer];

    // Transfer payment from Consumer to Prosumer.
        transferFrom(energyPairs[i].energyConsumer, energyPairs[i].energyProsumer, energyPairs[i].energyAmount * price);
        
        emit energyTransfer(energyPairs[i].energyProsumer, energyPairs[i].energyConsumer, energyPairs[i].energyAmount);  // emit an event confirming payment.
        
// The energyArray is a two-dimensional dynamic array used to store the energy transaction history for each user (both consumers and prosumers) in the contract.
// Each row in the energyArray represents a user, and the columns within each row represent different energy transactions made by that user.
// Stored in the energyStruct is the user's ID, the energy owner (the user's address), the energy amount, the energy state, and the timestamp when the energy bid was made. 
        energyStruct memory energy_temp = energyStruct(userIDConsumer, energyPairs[i].energyConsumer, energyPairs[i].energyAmount, 4, block.timestamp);
        energyArray[userIDConsumer].push(energy_temp);

// Two entries are added to the energyArray for each energy pair, one for the consumer and one for the prosumer.       
// If storage efficiency is a concern and both the consumer and prosumer entries contain identical information, 
// an alternative approach could be to store only one entry for each energy pair            
        energy_temp = energyStruct(userIDProsumer, energyPairs[i].energyProsumer, energyPairs[i].energyAmount, 4, block.timestamp);
        energyArray[userIDProsumer].push(energy_temp);
    }
    
    delete energyPairs;
    emit logGeneration(0);
    }
}
// [1]	LinkedIn, “LinkedIn Blockchain, Ethereum and Hyperledger Courses,” https://www.linkedin.com/learning/paths/become-a-blockchain-developer?trk=learning-topics_learning-search-card_search-card&upsellOrderOrigin=default_guest_learning.
// [2]	ethereum.org, “ERC-20 Token Standard,” https://ethereum.org/en/developers/docs/standards/tokens/erc-20/.
// [3]	J. G. Song, E. S. Kang, H. W. Shin, and J. W. Jang, “A smart contract-based p2p energy trading system with dynamic pricing on ethereum blockchain,” Sensors, vol. 21, no. 6, pp. 1–27, Mar. 2021, doi: 10.3390/s21061985.
// [4]	I. El-Sayed, K. Khan, X. Dominguez, and P. Arboleya, “A real pilot-platform implementation for blockchain-based peer-to-peer energy trading,” in IEEE Power and Energy Society General Meeting, IEEE Computer Society, Aug. 2020. doi: 10.1109/PESGM41954.2020.9281855.
// [5]	Kirli D et al., “Smart contract implementation example - Tutorial for Smart Contract Development with Python: Application to local Energy markets,” 2021. [Online]. Available: https://github.com/desenk/energy-smart-contract
 
