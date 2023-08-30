// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

contract BinaryBits {
    address immutable ADMIN;
    uint articleCount;
    uint commentCount;

    constructor(address Admin) {
        ADMIN = Admin;
        articleCount = 0;
    }

    modifier isAdmin() {
        require(
            msg.sender == ADMIN,
            "this function is only accesible by Admin"
        );
        _;
    }

    struct Comment {
        uint256 id;
        bytes commentURI;
        address author;
        uint256 replyTo;
        uint articleId;
    }

    struct Article {
        uint256 id;
        bytes articleURI;
        address author;
        address[] likes;
        address[] dislikes;
        uint[] commentIds;
    }

    event ArticlePublished(Article article);
    event ArticleUpdated(Article newArticle);
    event ArticleLiked(uint articleId, address likedBy);
    event ArticleDisLiked(uint articleId, address dislikedBy);
    event CommentAdded(
        uint256 id,
        bytes commentURI,
        address author,
        uint256 replyTo,
        uint articleId
    );

    mapping(uint => Article) idToArticle;
    mapping(address => uint[]) userToArticleIds;
    mapping(uint => Comment) idToComment;
    mapping(uint256 => uint256[]) articleIdToCommentIds;
    mapping(uint256 => uint256[]) commentIdToReplyIds; //reply is also a comment

    // mapping(address => uint256[]) addressToCommentIds;
    // mapping(uint256 => Comment) commentIdToComment;

    function publishArticle(bytes calldata articleURI) public {
        require(articleURI.length != 0, "articleURI is required to have value");
        address[] memory likes;
        address[] memory dislikes;
        uint[] memory comments;
        articleCount = articleCount + 1;
        Article memory article = Article(
            articleCount,
            articleURI,
            msg.sender,
            likes,
            dislikes,
            comments
        );
        userToArticleIds[msg.sender].push(articleCount);
        idToArticle[articleCount] = article;
        emit ArticlePublished(article);
    }

    function isAuthorOfArticle(uint _articleId) public view returns (bool) {
        uint[] storage articleIds = userToArticleIds[msg.sender];
        for (uint i = 0; i < articleIds.length; i++) {
            if (articleIds[i] == _articleId) {
                return true; // The articleId is present for the msg.sender
            }
        }
        return false; // The articleId is not present for the msg.sender
    }

    function updateArticle(
        uint256 articleId,
        bytes calldata newArticleURI
    ) public {
        require(
            newArticleURI.length != 0,
            "articleURI is required to have value"
        );
        require(articleId > 0);
        require(
            idToArticle[articleId].author == msg.sender,
            "not authorised to update this Article"
        );
        idToArticle[articleId].articleURI = newArticleURI;
        emit ArticleUpdated(idToArticle[articleId]);
    }

    function deleteArticle(uint256 articleId) public {
        require(
            idToArticle[articleId].author == msg.sender,
            "not authorised to delete this Article"
        );
        delete idToArticle[articleId];
    }

    function getArticle(
        uint256 articleId
    ) public view returns (Article memory article) {
        require(idToArticle[articleId].id > 0, "require a valid article Id");
        return idToArticle[articleId];
    }

    function getArticlesByAuthor(
        address author
    ) public view returns (Article[] memory articles) {
        require(
            userToArticleIds[author].length != 0,
            "author don't have Articles"
        );
        uint numArticles = userToArticleIds[author].length;
        articles = new Article[](numArticles);

        for (uint i = 0; i < numArticles; i++) {
            articles[i] = idToArticle[userToArticleIds[author][i]];
        }
        return articles;
    }

    function hasUserLikedArticle(
        uint _articleId,
        address _user
    ) internal view returns (bool, uint) {
        for (uint i = 0; i < idToArticle[_articleId].likes.length; i++) {
            if (idToArticle[_articleId].likes[i] == _user) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function likeArticle(uint256 articleId) public {
        require(idToArticle[articleId].id > 0, "id is invalid");
        (bool value, ) = hasUserLikedArticle(articleId, msg.sender);
        require(!value, "you have already liked this article"); //check if already liked
        idToArticle[articleId].likes.push(msg.sender);
        emit ArticleLiked(articleId, msg.sender);
    }

    function hasUserDisLikedArticle(
        uint _articleId,
        address _user
    ) internal view returns (bool, uint) {
        for (uint i = 0; i < idToArticle[_articleId].dislikes.length; i++) {
            if (idToArticle[_articleId].dislikes[i] == _user) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function dislikeArticle(uint256 articleId) public {
        require(idToArticle[articleId].id > 0, "id is invalid");
        (bool value, ) = hasUserDisLikedArticle(articleId, msg.sender);
        require(!value, "you have already liked this article"); //check if already disliked
        idToArticle[articleId].dislikes.push(msg.sender);
        emit ArticleDisLiked(articleId, msg.sender);
    }

    function commentOnArticle(uint256 articleId, bytes memory comment) public {
        require(comment.length > 0, "comment should not be empty");
        require(idToArticle[articleId].id > 0, "id is invalid");
        commentCount = commentCount + 1;
        idToComment[commentCount] = Comment(
            commentCount,
            comment,
            msg.sender,
            0,
            articleId
        );
        idToArticle[articleId].commentIds.push(commentCount);
        emit CommentAdded(commentCount, comment, msg.sender, 0, articleId);
    }

    function replyToComment(uint256 commentId, bytes memory reply) public {
        require(reply.length > 0, "reply should not be empty");
        require(idToComment[commentId].articleId > 0, "id is invalid");
        commentCount = commentCount + 1;

        idToComment[commentCount] = Comment(
            commentCount,
            reply,
            msg.sender,
            commentId,
            idToComment[commentId].articleId
        );
        idToArticle[idToComment[commentId].articleId].commentIds.push(
            commentCount
        );
        emit CommentAdded(
            commentCount,
            reply,
            msg.sender,
            0,
            idToComment[commentId].articleId
        );
    }
}
