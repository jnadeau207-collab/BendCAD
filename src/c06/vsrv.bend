import Base

def v_nth(xs: List<&2, String>, +i: Nat) -> String:
  match xs:
    case []: ""
    case +h <> t:
      match i:
        case 0n: h
        case 1n+(+j): v_nth(t, j)

def v_head(xs: List<&2, String>) -> String:
  match xs:
    case []: ""
    case +h <> t: h

def v_clean(+p: String) -> String:
  +q = v_head(String.split(v_head(String.split(p, '?')), '#'))
  Bool.pick(String, Bool.or(String.eq(q, ""), String.eq(q, "/")), "/index.html", q)

def v_path(+req: String) -> String:
  v_clean(v_nth(String.split(v_head(String.split(req, '\n')), ' '), 1n))

def v_safe(+p: String) -> Bool:
  Bool.and(String.starts_with(p, "/"), Bool.not(String.contains(p, "..")))

def v_ctype(+p: String) -> String:
  Bool.pick(String, String.ends_with(p, ".html"), "text/html; charset=utf-8",
    Bool.pick(String, String.ends_with(p, ".js"), "text/javascript; charset=utf-8",
      Bool.pick(String, String.ends_with(p, ".json"), "application/json",
        Bool.pick(String, Bool.or(String.ends_with(p, ".stp"), String.ends_with(p, ".step")), "model/step",
          Bool.pick(String, String.ends_with(p, ".css"), "text/css; charset=utf-8",
            Bool.pick(String, String.ends_with(p, ".svg"), "image/svg+xml",
              "text/plain; charset=utf-8"))))))

def v_hdr(+code: String, +ct: String) -> String:
  "HTTP/1.1 " ++ code ++ "\r\nContent-Type: " ++ ct ++ "\r\nCache-Control: no-store\r\nConnection: close\r\n\r\n"

law v_got:
  for d: File & Result<&1, &1, (U32 & String), String>
  IO(Result<&1, &1, U32 & String, String>)

def v_got(d):
  (f, r) = d
  do IO<Result<&1, &1, U32 & String, String>>:
    x : Unit <- File.close(f)
    IO.pure(Result<&1, &1, U32 & String, String>, r)

law v_sz:
  for f: File
  for r: Result<&1, &1, (U32 & String), U32>
  IO(Result<&1, &1, U32 & String, String>)

def v_sz(f, r):
  match r:
    case Fail{e}:
      do IO<Result<&1, &1, U32 & String, String>>:
        x : Unit <- File.close(f)
        IO.pure(Result<&1, &1, U32 & String, String>, Fail{e})
    case Done{n}:
      do IO<Result<&1, &1, U32 & String, String>>:
        d : File & Result<&1, &1, (U32 & String), String> <- File.read(f, U32.add(n, 1))
        v_got(d)

law v_size:
  for m: File & Result<&1, &1, (U32 & String), U32>
  IO(Result<&1, &1, U32 & String, String>)

def v_size(m):
  (f, r) = m
  v_sz(f, r)

law v_open:
  for r: Result<&1, &1, (U32 & String), File>
  IO(Result<&1, &1, U32 & String, String>)

def v_open(r):
  match r:
    case Fail{e}: IO.pure(Result<&1, &1, U32 & String, String>, Fail{e})
    case Done{f}:
      do IO<Result<&1, &1, U32 & String, String>>:
        m : File & Result<&1, &1, (U32 & String), U32> <- File.size(f)
        v_size(m)

law v_read:
  for path: String
  IO(Result<&1, &1, U32 & String, String>)

def v_read(path):
  do IO<Result<&1, &1, U32 & String, String>>:
    r : Result<&1, &1, (U32 & String), File> <- File.open(path, "r")
    v_open(r)

law v_done:
  for m: Socket & Result<&1, &1, (U32 & String), Unit>
  IO(Unit)

def v_done(m):
  (s, r) = m
  Socket.close(s)

law v_send:
  for s: Socket
  for ct: String
  for res: Result<&1, &1, (U32 & String), String>
  IO(Unit)

def v_send(s, ct, res):
  match res:
    case Done{body}:
      do IO<Unit>:
        m : Socket & Result<&1, &1, (U32 & String), Unit> <- TCP.send(s, v_hdr("200 OK", ct) ++ body)
        v_done(m)
    case Fail{e}:
      do IO<Unit>:
        m : Socket & Result<&1, &1, (U32 & String), Unit> <- TCP.send(s, v_hdr("404 Not Found", "text/plain") ++ "not found\n")
        v_done(m)

def v_serve_go(ok: Bool, s: Socket, +dir: String, +path: String) -> IO(Unit):
  match ok:
    case False{}: v_send(s, "text/plain", Fail{(0, "bad path")})
    case True{}:
      do IO<Unit>:
        res : Result<&1, &1, (U32 & String), String> <- v_read(dir ++ path)
        v_send(s, v_ctype(path), res)

def v_serve(s: Socket, +dir: String, +path: String) -> IO(Unit):
  v_serve_go(v_safe(path), s, dir, path)

def v_req2(s: Socket, r: Result<&1, &1, (U32 & String), String>, +dir: String) -> IO(Unit):
  match r:
    case Fail{e}: Socket.close(s)
    case Done{req}: v_serve(s, dir, v_path(req))

def v_req(q: Socket & Result<&1, &1, (U32 & String), String>, +dir: String) -> IO(Unit):
  (s, r) = q
  v_req2(s, r, dir)

def v_conn(r: Result<&1, &1, (U32 & String), Socket>, +dir: String) -> IO(Unit):
  match r:
    case Fail{e}: IO.pure(Unit, Unit{})
    case Done{s}:
      do IO<Unit>:
        q : Socket & Result<&1, &1, (U32 & String), String> <- TCP.recv(s, 16384)
        v_req(q, dir)

def v_one(m: Listener & Result<&1, &1, (U32 & String), Socket>, +dir: String) -> IO(Listener):
  (l, r) = m
  do IO<Listener>:
    u : Unit <- v_conn(r, dir)
    IO.pure(Listener, l)

def v_loop(n: Nat, l: Listener, +dir: String) -> IO(Unit):
  match n:
    case 0n: IO.print("view request budget spent")
    case 1n+f:
      do IO<Unit>:
        m : Listener & Result<&1, &1, (U32 & String), Socket> <- TCP.accept(l)
        l2 : Listener <- v_one(m, dir)
        v_loop(f, l2, dir)

def view(+port: U32, +dir: String) -> IO(Unit):
  do IO<Unit>:
    r : Result<&1, &1, (U32 & String), Listener> <- TCP.listen("127.0.0.1", port)
    l : Listener <- IO.pass(Listener, r)
    u : Unit <- IO.print("viewer at http://127.0.0.1:" ++ U32.show(port) ++ "/ serving " ++ dir)
    v_loop(100000000n, l, dir)
