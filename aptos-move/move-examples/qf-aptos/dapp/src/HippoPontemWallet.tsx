import React, {
  useEffect, useState, SyntheticEvent, useCallback,
} from 'react';
import { useWallet, WalletName } from '@manahippo/aptos-wallet-adapter';

import './styles.scss';
import { TAptosCreateTx } from './types';
import { camelCaseKeysToUnderscore } from './utils';
import {
  SendTransaction, Address, BasicModal, Hint,
} from './components';
import { localStorageKey } from './consts';
import { Loader } from './components/Loader';
import { Initialize } from './components/transactions/QfInitialize';
import { StartRound } from './components/transactions/QfStartRound';
import { BatchUploadProject } from './components/transactions/QfBatchUploadProject';
import { SetFund } from './components/transactions/QfSetFund';
import { BatchVote } from './components/transactions/QfBatchVote';
import { EndRound } from './components/transactions/QfEndRound';
import { WithdrawAll } from './components/transactions/QfWithdrawAll';
import { AddTrack } from './components/transactions/QfAddTrack';

export const HippoPontemWallet = ({ autoConnect }: { autoConnect: boolean }) => {
  const {
    account,
    connected,
    wallets,
    wallet,
    disconnect,
    select,
    signAndSubmitTransaction,
  } = useWallet();

  const [currentAdapterName, setAdapterName] = useState<string | undefined>(wallet?.adapter.name);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [currentAddress, setCurrentAddress] = useState(account?.address);
  const [loading, setLoading] = useState(true);
  const onModalClose = () => setIsModalOpen(false);
  const onModalOpen = () => setIsModalOpen(true);

  const adapters = wallets.map((item) => ({
    name: item?.adapter.name,
    icon: item?.adapter.icon,
  }));

  const handleSendTransaction = async (tx: TAptosCreateTx) => {
    const payload = camelCaseKeysToUnderscore(tx.payload);
    const options = {
      max_gas_amount: tx?.maxGasAmount,
      gas_unit_price: tx?.gasUnitPrice,
      expiration_timestamp_secs: tx?.expiration,
    };
    try {
      const { hash } = await signAndSubmitTransaction(payload, options);
      return hash;
    } catch (e) {
      console.log(e);
    }
  };

  const handleDisconnect = useCallback(async () => {
    try {
      await disconnect();
    } catch (error) {
      console.log(error);
    } finally {
      setAdapterName(undefined);
    }
  }, [disconnect]);

  const handleAdapterClick = useCallback(async (event: SyntheticEvent<HTMLButtonElement>) => {
    const walletName = (event.currentTarget as HTMLButtonElement).getAttribute('data-value');
    try {
      if (walletName) {
        select(walletName as WalletName);
        setAdapterName(walletName);
        onModalClose();
      }
    } catch (error) {
      console.log(error);
    }
  }, [select]);

  useEffect(() => {
    setCurrentAddress(account?.address);
  }, [account]);

  useEffect(() => {
    let alreadyConnectedWallet = localStorage.getItem(localStorageKey);
    if (alreadyConnectedWallet) {
      if (alreadyConnectedWallet.startsWith('"')) {
        alreadyConnectedWallet = JSON.parse(alreadyConnectedWallet) as string;
      }
      setAdapterName(alreadyConnectedWallet);
      if (autoConnect && currentAddress) setLoading(false);
    } else {
      setLoading(false);
    }
  }, [autoConnect, currentAddress]);

  if (loading) return <Loader />;

  return (
    <div className="wallet">
      {!connected && <button className='w-button' onClick={onModalOpen}>Connect wallet</button>}
      {connected && <button className='w-button' onClick={handleDisconnect}>Disconnect wallet</button>}

      <Address walletName={currentAdapterName} address={currentAddress} />

      {connected && (<div>
        <SendTransaction sender={currentAddress} onSendTransaction={handleSendTransaction} />
        <Initialize sender={currentAddress} onSendTransaction={handleSendTransaction} />
        <AddTrack sender={currentAddress} onSendTransaction={handleSendTransaction} />
        <StartRound sender={currentAddress} onSendTransaction={handleSendTransaction} />
        <BatchUploadProject sender={currentAddress} onSendTransaction={handleSendTransaction} />
        <SetFund sender={currentAddress} onSendTransaction={handleSendTransaction} />
        <BatchVote sender={currentAddress} onSendTransaction={handleSendTransaction} />
        <EndRound sender={currentAddress} onSendTransaction={handleSendTransaction} />
        <WithdrawAll sender={currentAddress} onSendTransaction={handleSendTransaction} />
      </div>
      )}

      {!connected && <Hint hint={'connect wallet'}/>}

      <BasicModal
        adapters={adapters}
        isOpen={isModalOpen}
        handleClose={onModalClose}
        handleAdapterClick={handleAdapterClick}
      />
    </div>
  );
};
