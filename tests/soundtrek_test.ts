import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Can create new audio diary entry",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const title = "Beach Waves";
    const timestamp = types.uint(1234567890);
    const location = {
      latitude: types.int(34052235),
      longitude: types.int(-118243683)
    };
    const audioHash = "QmHash123...";
    const isPublic = true;

    const block = chain.mineBlock([
      Tx.contractCall('soundtrek', 'create-entry',
        [
          types.utf8(title),
          timestamp,
          types.tuple(location),
          types.ascii(audioHash),
          types.bool(isPublic)
        ],
        deployer.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk().expectUint(1);
  }
});

Clarinet.test({
  name: "Can like public entries",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const user1 = accounts.get('wallet_1')!;
    
    // First create a public entry
    let block = chain.mineBlock([
      Tx.contractCall('soundtrek', 'create-entry',
        [
          types.utf8("Test Entry"),
          types.uint(1234567890),
          types.tuple({
            latitude: types.int(34052235),
            longitude: types.int(-118243683)
          }),
          types.ascii("QmHash123..."),
          types.bool(true)
        ],
        deployer.address
      )
    ]);

    // Then like it
    block = chain.mineBlock([
      Tx.contractCall('soundtrek', 'like-entry',
        [types.uint(1)],
        user1.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk().expectBool(true);
  }
});

Clarinet.test({
  name: "Cannot like private entries",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const user1 = accounts.get('wallet_1')!;
    
    // Create private entry
    let block = chain.mineBlock([
      Tx.contractCall('soundtrek', 'create-entry',
        [
          types.utf8("Private Entry"),
          types.uint(1234567890),
          types.tuple({
            latitude: types.int(34052235),
            longitude: types.int(-118243683)
          }),
          types.ascii("QmHash123..."),
          types.bool(false)
        ],
        deployer.address
      )
    ]);

    // Try to like it
    block = chain.mineBlock([
      Tx.contractCall('soundtrek', 'like-entry',
        [types.uint(1)],
        user1.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectErr().expectUint(101);
  }
});
