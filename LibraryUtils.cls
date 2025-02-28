Class Library.LibraryUtils Extends %RegisteredObject
{

/// Description
ClassMethod AddBook() As %Status
{
    Set book = ##class(Library.Book).%New()
    read #!!, "本のタイトルを入力してください:",name
    set book.Title = name

    read #!!, "本の著者を入力してください:",author
    &sql(SELECT id INTO :id FROM Library.person WHERE Name = :author)
    if (id '= ""){
        set book.Author = ##class(Library.Person).%OpenId(id)
    }
    else{
        set newAuthor = ##class(Library.Person).%New()
        set newAuthor.Name = author
        set book.Author = newAuthor
        set statusPerson = newAuthor.%Save()
    }

    read !, "ノンフィクションの場合は「1」、フィクションの場合は「2」を入力してください:",genre
    if genre = "1" {
        set book.Genre = "ノンフィクション"
    }
    else{
        set book.Genre = "フィクション"
    }
    set status = book.%Save()
    return status
}

ClassMethod AddFriend() As %Status
{
    Set friend = ##class(Library.Person).%New()

    read #!!, "新しい友達を入力してください:",name
    set friend.Name = name

    read #!!, "新しい友達の電話番号を入力してください:",phoneNum
    Set friend.PhoneNumber = phoneNum

    set status = friend.%Save()
    return status
}

/// Description
ClassMethod PrintOne(id As %String) As %Status
{
    set book = ##class(Library.Book).%OpenId(id)

    if book = "" {
        write !,"エラー: ID ", id, " の本が見つかりません。"
        return $$$OK
    }

    write !,"この本は" , book.Title ,"と呼ばれ、" , book.Author.Name , "によって書かれました。" 
    write !, "これは",book.Genre, "の本です。"

    if book.Friend = ""{
        write !,"この本は現在図書館にあります。"
    }
    else{
        write !,"この本は現在",book.Friend.Name,"に貸出中です。"
    }
    return $$$OK
}

/// Description
ClassMethod PrintAll() As %Status
{
    &sql(DECLARE bookCursor CURSOR FOR 
         SELECT ID FROM Library.Book ORDER BY ID)

    &sql(OPEN bookCursor)
    
    
    While (1) {
        &sql(FETCH bookCursor INTO :id)
        if SQLCODE '= 0 { quit } // データがない場合はループを抜ける

        write !,"この本のID:"_id
        do ##class(Library.LibraryUtils).PrintOne(id)
    }

    &sql(CLOSE bookCursor)

    return $$$OK
}

/// Description
ClassMethod LoanBook(bookID As %String, friend As %String) As %Status
{
    Set check = ##class(Library.Book).%OpenId(bookID)
    if (check.Friend '="") {
        write !,"この本は現在貸し出し中です。",!,"新しい友人に貸し出す前に、ReturnBook メソッドを使用して本を返却してください。"
        quit $$$OK
    } else {
        &sql(SELECT id INTO :id FROM Library.person WHERE name = :friend)
        if (id = "") {
            write !,"この友人は登録されていません。",!,"新しい友人を追加するには、AddFriend メソッドを使用してください。"
            quit $$$OK
        }
        else{
            set friend = ##class(Library.Person).%OpenId(id)
            set check.Friend = friend
            write !,friend.Name,"に貸し出された本"
            set status = check.%Save()
        }
    }
    return $$$OK
}

/// Description
ClassMethod ReturnBook(id As %String) As %Status
{
    &sql(SELECT friend INTO :friendID FROM Library.book WHERE id = :id)
    set friend = ##class(Library.Person).%OpenId(friendID)
    set book = ##class(Library.Book).%OpenId(id)
    if friend = ""{
        write !,"この本は貸出されていません。",!,"LoanBook() メソッドを使用して友人に貸出してください。"
        quit $$$OK
    }
    else{
        write !, "返却者：",friend.Name
        set book.Friend = ""
        set status = book.%Save()
        set status = friend.%Save()
    }
    return $$$OK
}

/// Description
ClassMethod GetLoanedBooks() As %Status
{
    &sql(SELECT count(id) INTO :count FROM library.book WHERE friend IS NOT NULL)
    write !,"現在、",count,"冊の本が貸し出し中です。"
}

ClassMethod GetShelfBooks() As %Status
{
    &sql(SELECT count(id) INTO :count FROM library.book WHERE friend IS  NULL)
    write !,"現在、棚には",count,"冊の本があります。"
}

ClassMethod FriendOwe(friend As %String) As %Status
{
    &sql(SELECT id INTO :id FROM library.person WHERE Name = :friend)
    &sql(SELECT count(*) INTO :count FROM library.book WHERE friend= :id)
    write !,friend,"には現在、",count ,"冊の本を貸し出し中です。"
}

ClassMethod GetFriend(id As %String) As %Status
{
    set book = ##class(Library.Book).%OpenId(id) 
	set friend = book.Friend.Name 
	if (friend = ""){ 
		set friend = "なし" 
	} 
	write !,"この本は現在、 ",friend," に貸し出されています。"
}

}
