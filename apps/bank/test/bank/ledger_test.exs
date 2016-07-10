defmodule Bank.LedgerTest do
  use Bank.Case

  @moduletag isolation: :serializable

  setup _tags do
    alice = Account.build_wallet("alice") |> Repo.insert!
    bob = Account.build_wallet("bob") |> Repo.insert!
    {:ok, _} = Deposit.build(alice, ~M"100 USD") |> Ledger.write

    {:ok, %{alice: alice, bob: bob}}
  end

  test "write: success", %{alice: alice, bob: bob} do
    transactions = [
      {:debit, alice, "", ~M"10 USD"},
      {:credit, bob, "", ~M"10 USD"},
    ]

    assert {:ok, [%Entry{}, %Entry{}]} = Ledger.write(transactions)

    assert Ledger.balance(alice) == ~M"90 USD"
    assert Ledger.balance(bob) == ~M"10 USD"
  end

  test "write: different currencies", %{alice: alice, bob: bob} do
    transactions = [
      {:debit, alice, "", ~M"10 USD"},
      {:credit, bob, "", ~M"10 EUR"},
    ]

    assert {:error, :different_currencies} = Ledger.write(transactions)
  end

  test "write: credits not equal debits", %{alice: alice, bob: bob} do
    transactions = [
      {:debit, alice, "", ~M"10 USD"},
      {:credit, bob, "", ~M"9 USD"},
    ]

    assert {:error, :credits_not_equal_debits} = Ledger.write(transactions)
    assert Ledger.balance(alice) == ~M"100 USD"
    assert Ledger.balance(bob) == ~M"0 USD"
  end

  test "write: insufficient funds", %{alice: alice, bob: bob} do
    transactions = [
      {:debit, alice, "", ~M"900 USD"},
      {:credit, bob, "", ~M"900 USD"},
    ]

    assert {:error, :insufficient_funds} = Ledger.write(transactions)
  end
end