// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Upload {

  struct Access {
    address user;
    bool hasAccess;
  }

  enum UserRole { Client, Lawyer, Judge }

  struct UserData {
    string[] documentUrls;
    mapping(address => bool) documentOwnership;
    Access[] accessList;
    bool roleSet;
  }

  mapping(address => UserData) private users;
  mapping(address => UserRole) private userRoles;

  function setUserRole(address user, UserRole role) public {
    require(!users[user].roleSet, "Role has already been set for this user");
    require(msg.sender == user || userRoles[msg.sender] == UserRole.Judge, "Only Judge or self can set role");
    userRoles[user] = role;
    users[user].roleSet = true;
  }

  function addDocument(string memory documentUrl) public {
    users[msg.sender].documentUrls.push(documentUrl);
  }

  function allowAccess(address user) public {
      users[msg.sender].documentOwnership[user] = true;

      bool sharedWithUser = false;
      for (uint i = 0; i < users[msg.sender].accessList.length; i++) {
          if (users[msg.sender].accessList[i].user == user) {
              users[msg.sender].accessList[i].hasAccess = true;
              sharedWithUser = true;
              break;
          }
      }

      if (!sharedWithUser) {
          users[msg.sender].accessList.push(Access(user, true));
      }
  }

  function disallowAccess(address user) public {
      users[msg.sender].documentOwnership[user] = false;

      for (uint i = 0; i < users[msg.sender].accessList.length; i++) {
          if (users[msg.sender].accessList[i].user == user) {
              users[msg.sender].accessList[i].hasAccess = false;
              break;
          }
      }

      for (uint i = 0; i < users[user].accessList.length; i++) {
          if (users[user].accessList[i].user == msg.sender) {
              users[user].accessList[i].hasAccess = false;
              break;
          }
      }
  }

  function viewDocuments(address userAddress) public view returns (string[] memory) {
      UserRole senderRole = userRoles[msg.sender];
      UserRole targetRole = userRoles[userAddress];

      // Check if the sender has access to view documents of the target user
      require(
          msg.sender == userAddress ||
          (senderRole == UserRole.Judge && targetRole < UserRole.Judge) ||
          (senderRole == UserRole.Lawyer && targetRole < UserRole.Lawyer) ||
          (users[userAddress].documentOwnership[msg.sender]),
          "You don't have access"
      );

      return users[userAddress].documentUrls;
  }

  function shareAccess() public view returns (Access[] memory) {
    return users[msg.sender].accessList;
  }

  function getUserRole(address user) public view returns (UserRole) {
    return userRoles[user];
  }

  function getOwnerAddress() public view returns (address) {
    return msg.sender;
  }
}
