import React, { useState } from 'react';

import '../../styles.scss';
import { MaybeHexString } from 'aptos';
import { TAptosCreateTx } from '../../types';
import { aptosQFAddress } from '../../consts';

interface ISendTransaction {
  onSendTransaction: (tx: TAptosCreateTx) => Promise<any>;
  sender?: MaybeHexString | null;
}

export const Initialize = ({ onSendTransaction, sender }: ISendTransaction) => {
  const [transactionHash, setTransactionHash] = useState(null);
  const senderAddress = sender ? sender.toString() : '';

  const initialValue = {
    sender: senderAddress,
    gasUnitPrice: '100',
    maxGasAmount: '10000',
    expiration: new Date().getTime().toString(),
    payload: {
      arguments: ['0xf56b98bb0c73956924af03735c33f108cf19cd396a92b0ed4472301eb7225c70' as const],
      function: aptosQFAddress + '::qf::initialize',
      type: 'entry_function_payload' as const,
      typeArguments: [],
    },
  };
  const jsonPayload = JSON.stringify(initialValue, null, 2);

  const handleButton = () => {
    if (transactionHash) {
      setTransactionHash(null);
      return;
    }
    onSendTransaction(initialValue).then((hash) => {
      setTransactionHash(hash);
    }).catch((error) => {
      console.log(error);
    });
  };

  const showBackButton = !!transactionHash;

  return (
    <div className="send-transaction">
      <div> Initialize QF Contract </div>
      <div className="divider"/>
      {!transactionHash
        ? <div className='codeBlock'>
            <pre className='code'>
              {jsonPayload}
            </pre>
          </div>
        : <div className='send-transaction__hash'>
            <h5 className='send-transaction__title'>Success! Transaction hash:</h5>
            {transactionHash}
          </div>
      }
      <div className="divider"/>
      <button className="w-button send-transaction__button" onClick={handleButton}>{showBackButton ? 'Back' : 'Send'}</button>
    </div>
  );
};
