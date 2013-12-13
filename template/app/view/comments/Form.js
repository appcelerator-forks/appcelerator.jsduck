/**
 * The form for adding and editing comments.
 */
Ext.define('Docs.view.comments.Form', {
    /**
     * @cfg {Ext.dom.Element/HTMLElement} renderTo
     * Element where to render the form.
     */
    /**
     * @cfg {Object} user
     * Object describing currently logged in user.
     */
    /**
     * @cfg {String} definedIn
     * The name of the class the member which we're commenting is
     * defined in.  Should only be supplied when editing a member
     * belonging to parent class.
     */
    /**
     * @cfg {Boolean} userSubscribed
     * True when user is subscribed to this thread.
     */
    /**
     * @cfg {Boolean} updateComment
     * True to invoke the form in editing existing comment mode.
     * The default is to use new comment form.
     */
    /**
     * @cfg {String} content
     * The existing content that we're about to edit.
     */

    /**
     * Creates a new comment form inside the configured #renderTo element.
     * @param {Object} cfg
     */
    constructor: function(cfg) {
        Ext.apply(this, cfg);

        var innerTpl = [
            '<div class="com-meta">',
                '<img class="avatar" width="25" height="25"',
                    ' src="http://www.gravatar.com/avatar/{emailHash}?s=25&amp;r=PG&amp;d=http://www.sencha.com/img/avatar.png">',
                '<div class="author">Logged in as {userName}</div>',
                '<label class="subscribe">',
                    'Email updates? <input type="checkbox" class="subscriptionCheckbox" <tpl if="userSubscribed">checked="checked"</tpl> /><span class="sep"> | </span>',
                '</label>',
                '<a href="#" class="toggleCommentGuide">View help &#8595;</a>',
                '<input type="submit" class="sub {[values.updateComment ? "update" : "post"]}Comment" value="{[values.updateComment ? "Update" : "Post"]} comment" />',
                '<tpl if="updateComment">',
                    ' or <a href="#" class="cancelUpdateComment">cancel</a>',
                '</tpl>',
            '</div>',
            '<div class="commentGuideTxt" style="display: none">',
                '<ul>',
                    '<li>Comments should be an <strong>extension</strong> of the documentation.<br>',
                    ' Inform us about bugs in documentation.',
                    ' Give useful tips to other developers.',
                    ' Warn about bugs and problems that might bite.',
                    '</li>',
                    "<li>Don't post comments for:",
                    '<ul>',
                        '<li><strong>Questions about code or usage</strong>',
                        ' - use the <a href="http://www.sencha.com/forum" target="_blank">Sencha Forum</a>.</li>',
                        '<li><strong>SDK bugs</strong>',
                        ' - use the <a href="http://www.sencha.com/forum" target="_blank">Sencha Forum</a>.</li>',
                        '<li><strong>Docs App bugs</strong>',
                        ' - use the <a href="https://github.com/senchalabs/jsduck/issues" target="_blank">GitHub Issue tracker</a>.</li>',
                    '</ul></li>',
                    '<li>Comments may be edited or deleted at any time by a moderator.</li>',
                    '<li>Avatars can be managed at <a href="http://www.gravatar.com" target="_blank">Gravatar</a> (use your forum email address).</li>',
                    '<li>To write a reply use <code>@username</code> syntax - the user will get notified.</li>',
                    '<li>Comments will be formatted using the Markdown syntax, eg:</li>',
                '</ul>',
                '<div class="markdown preview">',
                    '<h4>Markdown</h4>',
                    '<pre>',
                        "Here is a **bold** item\n",
                        "Here is an _italic_ item\n",
                        "Here is an `inline` code snippet\n",
                        "Here is a [Link](#!/api)\n",
                        "\n",
                        "    Indent with 4 spaces\n",
                        "    for a code snippet\n",
                        "\n",
                        "1. Here is a numbered list\n",
                        "2. Second numbered list item\n",
                        "\n",
                        "- Here is an unordered list\n",
                        "- Second unordered list item\n",
                        "\n",
                        "End a line with two spaces&nbsp;&nbsp;\n",
                        "to create a line break\n",
                    '</pre>',
                '</div>',
                '<div class="markdown result">',
                    '<h4>Result</h4>',
                    'Here is a <strong>bold</strong> item<br/>',
                    'Here is an <em>italic</em> item<br/>',
                    'Here is an <code>inline</code> code snippet<br/>',
                    'Here is a <a href="#!/api">Link</a><br/>',
                    '<pre class="prettyprint">',
                    "Indent with 4 spaces\n",
                    "for a code snippet",
                    '</pre>',
                    '<ol>',
                        '<li>Here is a numbered list</li>',
                        '<li>Second numbered list item</li>',
                    '</ol>',
                    '<ul>',
                        '<li>Here is an unordered list</li>',
                        '<li>Second unordered list item</li>',
                    '</ul>',
                    'End a line with two spaces<br/>to create a line break<br/><br/>',
                '</div>',
            '</div>'
        ];

        if (this.updateComment) {
            this.tpl = new Ext.XTemplate(
                '<form class="editCommentForm">',
                    '<span class="action">Edit comment</span>',
                    '<textarea>{content}</textarea>',
                    innerTpl.join(''),
                '</form>'
            );
        }
        else {
            this.tpl = new Ext.XTemplate(
                '<div class="new-comment{[values.hide ? "" : " open"]}">',
                    '<form class="newCommentForm">',
                        '<div class="postCommentWrap">',
                            '<tpl if="definedIn">',
                                "<p><b>Be aware.</b> This comment will be posted to <b>{definedIn}</b> class, ",
                                "from where this member is inherited from.</p>",
                            '</tpl>',
                            '<textarea></textarea>',
                            innerTpl.join(''),
                        '</div>',
                    '</form>',
                '</div>'
            );
        }

        this.render();
    },

    render: function() {
        var cfg = Ext.apply({
            definedIn: this.definedIn,
            updateComment: this.updateComment,
            content: this.content,
            userSubscribed: this.userSubscribed
        }, this.user);

        var wrap = this.tpl.overwrite(this.renderTo, cfg, true);
        this.makeCodeMirror(wrap.down('textarea').dom);
    },

    makeCodeMirror: function(textarea) {
        textarea.editor = CodeMirror.fromTextArea(textarea, {
            mode: 'markdown',
            lineWrapping: true,
            indentUnit: 4
        });
    }

});
