;;; alchemist-goto-test.el ---

;; Copyright © 2014-2015 Samuel Tonini
;;
;; Author: Samuel Tonini <tonini.samuel@gmail.com>

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;; Code:

(ert-deftest extract-function ()
  (should (equal (alchemist-goto--extract-function ":gen_tcp.accept")
                 "accept"))
  (should (equal (alchemist-goto--extract-function ":erlang")
                 nil))
  (should (equal (alchemist-goto--extract-function "List.duplicate")
                 "duplicate"))
  (should (equal (alchemist-goto--extract-function "_duplicate")
                 "_duplicate"))
  (should (equal (alchemist-goto--extract-function "_duplicated?")
                 "_duplicated?"))
  (should (equal (alchemist-goto--extract-function "parse!")
                 "parse!"))
  (should (equal (alchemist-goto--extract-function "Enum.take!")
                 "take!"))
  (should (equal (alchemist-goto--extract-function "String.Chars.impl_for")
                 "impl_for"))
  (should (equal (alchemist-goto--extract-function "String.Chars.Atom")
                 nil)))

(ert-deftest extract-module ()
  (should (equal (alchemist-goto--extract-module ":gen_tcp.accept")
                 ":gen_tcp"))
  (should (equal (alchemist-goto--extract-module ":erlang")
                 ":erlang"))
  (should (equal (alchemist-goto--extract-module "List.duplicate")
                 "List"))
  (should (equal (alchemist-goto--extract-module "Whatever._duplicate")
                 "Whatever"))
  (should (equal (alchemist-goto--extract-module "Module.read!")
                 "Module"))
  (should (equal (alchemist-goto--extract-module "String.Chars.impl_for")
                 "String.Chars"))
  (should (equal (alchemist-goto--extract-module "String.Chars.Atom")
                 "String.Chars.Atom"))
  (should (equal (alchemist-goto--extract-module "String.Chars.")
                 "String.Chars"))
  (should (equal (alchemist-goto--extract-module "String.concat")
                 "String"))
  (should (equal (alchemist-goto--extract-module "to_string")
                 nil)))

(ert-deftest check-if-an-elixir-source-file ()
  (should-not (equal (alchemist-goto--elixir-file-p "lib/elixir/lib/list.ex")
                     nil))
  (should-not (equal (alchemist-goto--elixir-file-p "lib/elixir/lib/enum.exs")
                     nil))
  (should (equal (alchemist-goto--elixir-file-p "lib/kernel/lib/gen_tcp.erl")
                 nil)))

(ert-deftest check-if-an-erlang-source-file ()
  (should-not (equal (alchemist-goto--erlang-file-p "lib/elixir/src/list.erl")
                     nil))
  (should-not (equal (alchemist-goto--erlang-file-p "lib/elixir/src/elixir.erl")
                     nil))
  (should (equal (alchemist-goto--erlang-file-p "lib/kernel/lib/enum.ex")
                 nil)))

(ert-deftest build-an-elixir-ex-core-file ()
  (set (make-local-variable 'alchemist-goto-elixir-source-dir) "/elixir-source/")
  (should (equal (alchemist-goto--build-elixir-ex-core-file
                  "/private/tmp/elixir-asdASDq/lib/elixir/lib/elixir.ex")
                 "/elixir-source/lib/elixir/lib/elixir.ex")))

(ert-deftest build-an-elixir-erl-core-file ()
  (set (make-local-variable 'alchemist-goto-elixir-source-dir) "/elixir-source/")
  (should (equal (alchemist-goto--build-elixir-erl-core-file
                  "/private/tmp/elixir-asdASDq/lib/elixir/src/elixir.erl")
                 "/elixir-source/lib/elixir/src/elixir.erl")))

(ert-deftest build-an-erlang-core-file ()
  (set (make-local-variable 'alchemist-goto-erlang-source-dir) "/erlang-source/")
  (should (equal (alchemist-goto--build-erlang-core-file
                  "/private/tmp/erlang-vKyIIl/otp-OTP-17.4/lib/edoc/src/edoc_data.erl")
                 "/erlang-source/lib/edoc/src/edoc_data.erl")))


(ert-deftest test-alchemist-goto--extract-symbol ()
  (should (equal (alchemist-goto--extract-symbol "def dgettext(backend, domain, msgid, bindings \\ %{})")
                 "def dgettext(backend, domain, msgid, bindings \\ %{})"))
  (should (equal (alchemist-goto--extract-symbol "def dgettext(backend, domain, msgid, bindings) when is_list(bindings) do")
                 "def dgettext(backend, domain, msgid, bindings) when is_list(bindings)"))
  (should (equal (alchemist-goto--extract-symbol "def dgettext(one) do: :atom")
                 "def dgettext(one)"))
  (should (equal (alchemist-goto--extract-symbol "def dgettext(backend, domain, msgid, bindings) do")
                 "def dgettext(backend, domain, msgid, bindings)"))
  (should (equal (alchemist-goto--extract-symbol "defmodule Test do")
                 "defmodule Test"))
  (should (equal (alchemist-goto--extract-symbol "defmodule Test.Module do")
                 "defmodule Test.Module"))
  (should (equal (alchemist-goto--extract-symbol "def function?(fn) do")
                 "def function?(fn)"))
  (should (equal (alchemist-goto--extract-symbol "defp render! do")
                 "defp render!"))
  (should (equal (alchemist-goto--extract-symbol "defmacro __using__(_) do")
                 "defmacro __using__(_)")))

(ert-deftest get-aliases-of-an-elixir-module ()
  (should (equal (list '("Phoenix.Router.Resource" "Special")
                       '("Phoenix.Router.Scope" "Scope"))
                 (with-temp-buffer
                   (alchemist-mode)
                   (insert "
defmodule Phoenix.Router do

  alias Phoenix.Router.Resource, as: Special
  alias Phoenix.Router.Scope

  @doc false
  defmacro scope(path, options, do: context) do
    options = quote do
      path = unquote(path)
      case unquote(options) do
        alias when is_atom(alias) -> [path: path, alias: alias]
        options when is_list(options) -> Keyword.put(options, :path, path)
      end
    end
    do_scope(options, context)
  end

end")
                   (alchemist-goto--alises-of-current-buffer)))))

(ert-deftest match-functions-inside-buffer ()
  (should (string-match-p (alchemist-gogo--symbol-definition-regex "cwd!")
                          "  def cwd! do"))
  (should (string-match-p (alchemist-gogo--symbol-definition-regex "delete")
                          "  def delete(list, item) do"))
  (should (string-match-p (alchemist-gogo--symbol-definition-regex "do_zip")
                          "  defp do_zip(list, acc) do"))
  (should (string-match-p (alchemist-gogo--symbol-definition-regex "keymember?")
                          "  def keymember?(list, key, position) do"))
  (should (string-match-p (alchemist-gogo--symbol-definition-regex "has_key?")
                          "  def has_key?(map, key), do: :maps.is_key(key, map)"))
  (should (string-match-p (alchemist-gogo--symbol-definition-regex "left")
                          "  defmacro left or right do"))
  (should (string-match-p (alchemist-gogo--symbol-definition-regex "defimpl!")
                          "  defmacro defimpl!(name, opts, do_block \\ []) do"))
  (should (string-match-p (alchemist-gogo--symbol-definition-regex "parse!")
                          "  defmacro parse! do"))
  (should (string-match-p (alchemist-gogo--symbol-definition-regex "has_key?")
                          "  defmacrop has_key? do"))
  (should (string-match-p (alchemist-gogo--symbol-definition-regex "read")
                          "  defmacro read(source) do")))

(provide 'alchemist-goto-test)

;;; alchemist-goto-test.el ends here
