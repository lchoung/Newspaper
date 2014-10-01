//When given the objectIds of a group and a post, this function adds the post to the pendingPosts section of the group and into the pendingPosts section of every user in the group. In addition, it adds the groupId to the post.
Parse.Cloud.define("addPostToGroup", function(request, response) {
    Parse.Cloud.useMasterKey();
    var postQuery = new Parse.Query("Post");
    postQuery.get(request.params.postId, {
        success: function(post) {
            post.set("groupId", request.params.groupId);
            // Save the user.
            post.save(null, {
                success: function(postSaved) {
                    var query = new Parse.Query("Group");
                    query.get(request.params.groupId, {
                        success: function(group) {
                            if (!group.get("pendingPosts")) {
                                var arr = [];
                            } else {
                                var arr = group.get("pendingPosts");
                            }
                            var j = arr.indexOf(request.params.postId);
                            if (j < 0) {
                                arr.unshift(request.params.postId);
                                group.set("pendingPosts", arr);
                                if (!group.get("pendingTitles")) {
                                    var arr2 = [];
                                } else {
                                    var arr2 = group.get("pendingTitles");
                                }
                                arr2.unshift(request.params.postTitle);
                                group.set("pendingTitles", arr2);
                            }
                            // Save the group.
                            group.save(null, {
                                success: function(anotherUser) {
                                    // The group was saved successfully.
                                    var memberIds = group.get("memberIds");
                                    var len = memberIds.length;
                                    var count = 0;
                                    for (var i = 0; i < len; i++) {
                                        var userId = memberIds[i];
                                        var userQuery = new Parse.Query(Parse.User);
                                        userQuery.get(userId, {
                                            success: function(user) {
                                                if (!user.get("pendingPosts")) {
                                                    var userArr = [];
                                                } else {
                                                    var userArr = user.get("pendingPosts");
                                                }
                                                var k = userArr.indexOf(request.params.postId);
                                                if (k < 0) {
                                                    userArr.unshift(request.params.postId);
                                                    user.set("pendingPosts", userArr);
                                                    if (!user.get("pendingTitles")) {
                                                        var userArr2 = [];
                                                    } else {
                                                        var userArr2 = user.get("pendingTitles");
                                                    }
                                                    userArr2.unshift(request.params.postTitle);
                                                    user.set("pendingTitles", userArr2);
                                                }
                                                // Save the user.
                                                user.save(null, {
                                                    success: function(userSaved) {
                                                        count++;
                                                        if (count == len) {
                                                            response.success("Updated everything");
                                                        }
                                                    },
                                                    error: function(userSavedError) {
                                                        response.error("Could not save changes to user.");
                                                    }
                                                });
                                            },
                                            error: function(error) {
                                                response.error("Could not find user.");
                                            }
                                        });
                                    }
                                },
                                error: function(error) {
                                    // The save failed.
                                    // error is a Parse.Error with an error code and description.
                                    response.error("Could not save changes to group.");
                                }
                            });
                        },
                        error: function(error) {
                            response.error("Could not find group.");
                        }
                    });
                },
                error: function(postSavedError) {
                    response.error("Could not save changes to post.");
                }
            });
        },
        error: function(error) {
            response.error("Could not find post.");
        }
    });
});



//When given the objectId and title of a post, this function removes the post from the pendingPosts section of the group and from the pendingPosts section of every user in the group. It also adds the post to the newsfeed (and postIds) of the group and every user in the group. In addition, it sets the approved boolean to true for the post.
Parse.Cloud.define("approvePost", function(request, response) {
    Parse.Cloud.useMasterKey();
    var postQuery = new Parse.Query("Post");
    postQuery.get(request.params.postId, {
        success: function(post) {
            post.set("approved", true);
            post.set("draft", false);
            // Save the user.
            post.save(null, {
                success: function(postSaved) {
                    //The user was saved successfully.
                    //response.success("Successfully updated post.");
                    var query = new Parse.Query("Group");
                    query.get(post.get("groupId"), {
                        success: function(group) {
                            if (!group.get("pendingPosts")) {
                                var arr = [];
                                var arr1 = [];
                            } else {
                                var arr = group.get("pendingPosts");
                                var arr1 = group.get("pendingTitles");
                                var i = arr.indexOf(request.params.postId);
                                if (i != -1) {
                                    arr.splice(i, 1);
                                    arr1.splice(i, 1);
                                }
                            }
                            group.set("pendingPosts", arr);
                            group.set("pendingTitles", arr1);
                            if (!group.get("postIds")) {
                                var arr3 = [];
                            } else {
                                var arr3 = group.get("postIds");
                            }
                            var j = arr3.indexOf(request.params.postId);
                            if (j < 0) {
                                arr3.unshift(request.params.postId);
                                group.set("postIds", arr3);
                                if (!group.get("newsfeed")) {
                                    var arr2 = [];
                                } else {
                                    var arr2 = group.get("newsfeed");
                                }
                                arr2.unshift(request.params.postTitle);
                                group.set("newsfeed", arr2);
                            }
                            // Save the group.
                            group.save(null, {
                                success: function(anotherUser) {
                                    // The group was saved successfully.
                                    var memberIds = group.get("memberIds");
                                    var len = memberIds.length;
                                    var count = 0;
                                    for (var i = 0; i < len; i++) {
                                        var userId = memberIds[i];
                                        var userQuery = new Parse.Query(Parse.User);
                                        userQuery.get(userId, {
                                            success: function(user) {
                                                if (!user.get("pendingPosts")) {
                                                    var userArr = [];
                                                    var userArr1 = [];
                                                } else {
                                                    var userArr = user.get("pendingPosts");
                                                    var userArr1 = user.get("pendingTitles");
                                                    var i = userArr.indexOf(request.params.postId);
                                                    if (i != -1) {
                                                        userArr.splice(i, 1);
                                                        userArr1.splice(i, 1);
                                                    }
                                                }
                                                user.set("pendingPosts", userArr);
                                                user.set("pendingTitles", userArr1);
                                                if (!user.get("postIds")) {
                                                    var userArr3 = [];
                                                } else {
                                                    var userArr3 = user.get("postIds");
                                                }
                                                var k = userArr3.indexOf(request.params.postId);
                                                if (k < 0) {
                                                    userArr3.unshift(request.params.postId);
                                                    user.set("postIds", userArr3);
                                                    if (!user.get("newsfeed")) {
                                                        var userArr2 = [];
                                                    } else {
                                                        var userArr2 = user.get("newsfeed");
                                                    }
                                                    userArr2.unshift(request.params.postTitle);
                                                    user.set("newsfeed", userArr2);
                                                }
                                                // Save the user.
                                                user.save(null, {
                                                    success: function(userSaved) {
                                                        count++;
                                                        if (count == len) {
                                                            response.success("Updated everything");
                                                        }
                                                    },
                                                    error: function(userSavedError) {
                                                        response.error("Could not save changes to user.");
                                                    }
                                                });
                                            },
                                            error: function(error) {
                                                response.error("Could not find group.");
                                            }
                                        });
                                    }
                                },
                                error: function(error) {
                                    // The save failed.
                                    // error is a Parse.Error with an error code and description.
                                    response.error("Could not save changes to group.");
                                }
                            });
                        },
                        error: function(error) {
                            response.error("Could not find group.");
                        }
                    });
                },
                error: function(postSavedError) {
                    response.error("Could not save changes to post.");
                }
            });
        },
        error: function(error) {
            response.error("Could not find post.");
        }
    });
});



//When given the objectId and title of a post, this function removes the post from the pendingPosts section of the group and from the pendingPosts section of every user in the group. It also deletes the post. 
Parse.Cloud.define("deletePost", function(request, response) {
    Parse.Cloud.useMasterKey();
    var postQuery = new Parse.Query("Post");
    postQuery.get(request.params.postId, {
        success: function(post) {
            post.destroy(); {
                var query = new Parse.Query("Group");
                query.get(request.params.groupId, {
                    success: function(group) {
                        if (!group.get("pendingPosts")) {
                            var arr = [];
                            var arr1 = [];
                        } else {
                            var arr = group.get("pendingPosts");
                            var arr1 = group.get("pendingTitles");
                            var i = arr.indexOf(request.params.postId);
                            if (i != -1) {
                                arr.splice(i, 1);
                                arr1.splice(i, 1);
                            }
                        }
                        group.set("pendingPosts", arr);
                        group.set("pendingTitles", arr1);
                        // Save the group.
                        group.save(null, {
                            success: function(anotherUser) {
                                // The group was saved successfully.
                                var memberIds = group.get("memberIds");
                                var len = memberIds.length;
                                var count = 0;
                                for (var i = 0; i < len; i++) {
                                    var userId = memberIds[i];
                                    var userQuery = new Parse.Query(Parse.User);
                                    userQuery.get(userId, {
                                        success: function(user) {
                                            if (!user.get("pendingPosts")) {
                                                var userArr = [];
                                                var userArr1 = [];
                                            } else {
                                                var userArr = user.get("pendingPosts");
                                                var userArr1 = user.get("pendingTitles");
                                                var i = userArr.indexOf(request.params.postId);
                                                if (i != -1) {
                                                    userArr.splice(i, 1);
                                                    userArr1.splice(i, 1);
                                                }
                                            }
                                            user.set("pendingPosts", userArr);
                                            user.set("pendingTitles", userArr1);
                                            // Save the user.
                                            user.save(null, {
                                                success: function(userSaved) {
                                                    count++;
                                                    if (count == len) {
                                                        response.success("Updated everything");
                                                    }
                                                },
                                                error: function(userSavedError) {
                                                    response.error("Could not save changes to user.");
                                                }
                                            });
                                        },
                                        error: function(error) {
                                            response.error("Could not find user.");
                                        }
                                    });
                                }
                            },
                            error: function(error) {
                                response.error("Could not save changes to group.");
                            }
                        });
                    },
                    error: function(error) {
                        response.error("Could not find group.");
                    }
                });
            }
        },
        error: function(error) {
            response.error("Could not find post.");
        }
    });
});



//When given the objectId and title of a post, this updates the post title everywhere.
Parse.Cloud.define("changeTitle", function(request, response) {
    Parse.Cloud.useMasterKey();
    var postQuery = new Parse.Query("Post");
    postQuery.get(request.params.postId, {
        success: function(post) {
            post.destroy(); {
                var query = new Parse.Query("Group");
                query.get(request.params.groupId, {
                    success: function(group) {
                        if (!group.get("pendingPosts")) {
                            var arr = [];
                            var arr1 = [];
                        } else {
                            var arr = group.get("pendingPosts");
                            var arr1 = group.get("pendingTitles");
                            var i = arr.indexOf(request.params.postId);
                            if (i != -1) {
                                arr1[i] = request.params.postTitle;
                            }
                        }
                        group.set("pendingTitles", arr1);
                        // Save the group.
                        group.save(null, {
                            success: function(anotherUser) {
                                // The group was saved successfully.
                                var memberIds = group.get("memberIds");
                                var len = memberIds.length;
                                var count = 0;
                                for (var i = 0; i < len; i++) {
                                    var userId = memberIds[i];
                                    var userQuery = new Parse.Query(Parse.User);
                                    userQuery.get(userId, {
                                        success: function(user) {
                                            if (!user.get("pendingPosts")) {
                                                var userArr = [];
                                                var userArr1 = [];
                                            } else {
                                                var userArr = user.get("pendingPosts");
                                                var userArr1 = user.get("pendingTitles");
                                                var i = userArr.indexOf(request.params.postId);
                                                if (i != -1) {
                                                    userArr1[i] = request.params.postTitle;
                                                }
                                            }
                                            user.set("pendingTitles", userArr1);
                                            // Save the user.
                                            user.save(null, {
                                                success: function(userSaved) {
                                                    count++;
                                                    if (count == len) {
                                                        response.success("Updated everything");
                                                    }
                                                },
                                                error: function(userSavedError) {
                                                    response.error("Could not save changes to user.");
                                                }
                                            });
                                        },
                                        error: function(error) {
                                            response.error("Could not find user.");
                                        }
                                    });
                                }
                            },
                            error: function(error) {
                                response.error("Could not save changes to group.");
                            }
                        });
                    },
                    error: function(error) {
                        response.error("Could not find group.");
                    }
                });
            }
        },
        error: function(error) {
            response.error("Could not find post.");
        }
    });
});



Parse.Cloud.define("updateUser", function(request, response) {
    Parse.Cloud.useMasterKey();
    var userId = request.params.userId;
    var groupId = request.params.groupId;
    var gChannel = "g" + groupId;
    var userQuery = new Parse.Query(Parse.User);
    var groupQuery = new Parse.Query("Group");
    userQuery.get(userId, {
        success: function(user) {
            groupQuery.get(groupId, {
                success: function(group) {
                    var postQuery = new Parse.Query("Post");
                    postQuery.equalTo("author", userId);
                    postQuery.equalTo("draft", false);
                    postQuery.equalTo("approved", true);
                    postQuery.equalTo("groupId", groupId);
                    postQuery.descending("votes");
                    postQuery.find({
                        success: function(results) {
                            var congratulate = 0;
                            var dict = group.get("cred");
                            var sum = 0;
                            for (var i = 0; i < results.length; i++) {
                                var object = results[i];
                                sum += object.get("votes");
                            }
                            if(group.get("creator") == userId) {
                                   sum += group.get("minCred");
                                }
                            dict[userId] = sum;
                            group.set("cred", dict);
                            if (sum < group.get("minCred")) {
                                user.remove("adminGroups", groupId);
                                user.remove("channels", gChannel);
                            } else {
                                var adminGroups = user.get("adminGroups");
                                console.log(adminGroups);
                                user.addUnique("adminGroups", groupId);
                                user.addUnique("channels", gChannel);
                                if (dirty(user[@"adminGroups"])) //If this value has changed
                                {
                                    congratulate = 1;
                                }
                            }
                            user.save(null, {
                                success: function(saved) {
                                    group.save(null, {
                                        success: function(save) {
                                            response.success("Updated everything");
                                            if (congratulate == 1)
                                            {
                                                //Congratulate user
                                                var pushQuery = new Parse.Query(Parse.Installation);
                                                pushQuery.equalTo('user', user);

                                                var msg = "Congrats! You're now an admin of" + group.get("name");
                                                Parse.Push.send({
                                                    where: pushQuery,
                                                    data: {
                                                        alert: msg
                                                        }
                                                    }, {
                                                        success:function(){
                                                            console.log("Successfully pushed to new admin");
                                                        },
                                                        error: function(error){
                                                            console.log(error);
                                                        }
                                                    });
                                                    } 
                                                });
                                            }
                                        },
                                        error: function(error) {
                                            response.error("Did not save group");
                                        }
                                    });
                                },
                                error: function(error) {
                                    response.error("Did not save user");
                                }
                            });
                        },
                        error: function(error) {
                            response.error("Failed to get update");
                        }
                    });
                },
                error: function(error) {
                    response.error("Failed to get group");
                }
            });
        },
        error: function(error) {
            response.error("Failed to get user");
        }
    });
});



Parse.Cloud.define("fixGroup", function(request, response) {
    Parse.Cloud.useMasterKey();
    var groupId = request.params.groupId;
    var groupQuery = new Parse.Query("Group");
    groupQuery.get(groupId, {
        success: function(group) {
            var postQuery = new Parse.Query("Post");
            postQuery.equalTo("groupId", groupId);
            postQuery.descending("createdAt");
            postQuery.find({
                success: function(results) {
                    var pendingPosts = [];
                    var pendingTitles = [];
                    var newsfeed = [];
                    var postIds = [];
                    for (var i = 0; i < results.length; i++) {
                        var post = results[i];
                        if (post.get("approved")) {
                            newsfeed.push(post.get("title"));
                            postIds.push(post.id);
                        } else {
                            pendingTitles.push(post.get("title"));
                            pendingPosts.push(post.id);
                        }
                    }
                    group.set("pendingPosts", pendingPosts);
                    group.set("pendingTitles", pendingTitles);
                    group.set("newsfeed", newsfeed);
                    group.set("postIds", postIds);

                    group.save(null, {
                        success: function(saved) {
                            response.success("Fixed group");
                        },
                        error: function(error) {
                            response.error("Failed to save group ");
                        }
                    });
                },
                error: function(error) {
                    response.error("Failed to get posts");
                }
            });
        },
        error: function(error) {
            response.error("Failed to get group");
        }
    });
});



Parse.Cloud.define("fixUser", function(request, response) {
    Parse.Cloud.useMasterKey();
    var userId = request.params.userId;
    var userQuery = new Parse.Query(Parse.User);
    userQuery.get(userId, {
        success: function(user) {
            var groupQuery = new Parse.Query("Group");
            groupQuery.equalTo("memberIds", userId);
            groupQuery.find({
                success: function(groupResults) {
                    var credibility = 0;
                    var groups = [];
                    var groupIds = [];
                    for (var i = 0; i < groupResults.length; i++) {
                        var group = groupResults[i];
                        groups.push(group.get("name"));
                        groupIds.push(group.id);
                            if(group.get("creator") == userId) {
                            credibility += group.get("minCred");
                            }
                    }
                    user.set("groups", groups);
                    user.set("groupIds", groupIds);
                    var postQuery = new Parse.Query("Post");
                    postQuery.containedIn("groupId", groupIds);
                    postQuery.descending("createdAt");
                    postQuery.find({
                        success: function(results) {
                            var postNumber = 0;
                            var pendingPosts = [];
                            var pendingTitles = [];
                            var newsfeed = [];
                            var postIds = [];
                            for (var i = 0; i < results.length; i++) {
                                var post = results[i];
                                if (post.get("approved")) {
                                    newsfeed.push(post.get("title"));
                                    postIds.push(post.id);
                                    if (post.get("author") == userId) {
                                        credibility += post.get("votes");
                                        postNumber++;
                                    }
                                } else {
                                    pendingTitles.push(post.get("title"));
                                    pendingPosts.push(post.id);
                                }
                            }
                            user.set("pendingPosts", pendingPosts);
                            user.set("pendingTitles", pendingTitles);
                            user.set("newsfeed", newsfeed);
                            user.set("postIds", postIds);
                            user.set("credibility", credibility);
                            user.set("pubNumber", postNumber);
                            user.save(null, {
                                success: function(saved) {
                                    response.success("Fixed user");
                                },
                                error: function(error) {
                                    response.error("Failed to save user ");
                                }
                            });
                        },
                        error: function(error) {
                            response.error("Failed to get posts");
                        }
                    });
                },
                error: function(error) {
                    response.error("Failed to get groups");
                }
            });
        },
        error: function(error) {
            response.error("Failed to get user");
        }
    });
});