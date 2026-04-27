import {UserComment} from '../types/userComment';

export const COMMENTS: UserComment[] = [{id: 1, creatorName: "John Snow", content: "Some awesome data"}, {
  id: 2,
  creatorName: "John Snow",
  content: "An XSS <script>alert('XSS')</script> <IMG SRC=/ onerror=\"alert(String.fromCharCode(88,83,83))\"></img>"
}]
