# ShowBook
Demo App created using swiftUI and core data framework. Added unit testing. Design Pattern used MVVM.

# Sign Up View 
calls api to get list of countries and save it to core data along with last selected country.<br/>
for the first time it only calls api after that it fetches data from core data only.<br/>
Validate Email and Password using regex.<br/>
Save the user details in core data for login purpose.

# Login View 
Validate Email and Password using regex and check if user is present in core data.

# Dashboard View 
Can search books, add book mark by sliding the book items from tail and getting an button which can save book in core data.<br/>
filter book list with options such as title, average ratings, hits, also can clear the option selected.<br/>
can logout user from the logout button.<br/>
can navigate to Book marK view.<br/>
api call with debouncing textfield.<br/>
Load more books by stretching from bottom of the list to call api.

# Dashboard View 
Can search books, add book mark by sliding the book items from tail and getting an button which can save book in core data.<br/>
filter book list with options such as title, average ratings, hits, also can clear the option selected.<br/>
can logout user from the logout button.<br/>
can navigate to Book marK view.

# Limitations 
while saving books - not getting any id from api which means we had to use UUID in model for distinguish and while saving core data auto generates id so no proper way to save books with using predicates of every given data in book struct.<br/>
So when 2 book items have same title, author, rating, review, coverI(Cover id) only one will be saved. 

# Bookmark View 
shows the books from fetching it from core data.<br/>
can reload if the book is not present by stretching the list from top towards bottom.<br/>
The App maintain can maintain session, authenticity, privacy.<br/>
User 1 cannot see the bookmarked books of user 2 and vice versa.


