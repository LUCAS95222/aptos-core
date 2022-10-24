import React from "react";
import {
  WalletProvider,
  AptosWalletAdapter,
  PontemWalletAdapter,
  MartianWalletAdapter,
} from "@manahippo/aptos-wallet-adapter";

import "./styles.scss";
import { HippoPontemWallet } from "./HippoPontemWallet";

const localStorageKey = 'hippoWallet';

const wallets = [
  new AptosWalletAdapter(),
  new MartianWalletAdapter(),
  new PontemWalletAdapter(), 
];

const autoConnect = true;

export function App() {
  return (
    <div className="app">
      <WalletProvider
        wallets={wallets}
        localStorageKey={localStorageKey}
        autoConnect={autoConnect}
      >
        <HippoPontemWallet autoConnect={autoConnect} />
      </WalletProvider>
    </div>
  );
}

export default App;
