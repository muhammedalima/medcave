class MedicineData {
  // Store medicines by their generic name with all brand alternatives
  static final Map<String, Map<String, dynamic>> genericMedicines = {
    'Acetaminophen': {
      'description':
          'A pain reliever and fever reducer used for headaches, muscle aches, arthritis, backaches, toothaches, colds, and fevers.',
      'alternatives': [
        {
          'name': 'Tylenol',
          'linktobuy':
              'https://www.walgreens.com/store/c/tylenol-extra-strength-acetaminophen-caplets/ID=prod6041358-product'
        },
        {
          'name': 'Paracetamol',
          'linktobuy':
              'https://www.amazon.com/Paracetamol-Acetaminophen-Tablets-500mg-100/dp/B08L9T8K5P'
        },
        {
          'name': 'Crocin',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/crocin-advance-500mg-tablet-15-s'
        },
        {
          'name': 'Dolo 650',
          'linktobuy': 'https://www.1mg.com/drugs/dolo-650-tablet-20506'
        },
        {
          'name': 'Fevadol',
          'linktobuy':
              'https://www.pharmacyonline.com.au/fevadol-paracetamol-500mg-24-tablets'
        }
      ]
    },
    'Ibuprofen': {
      'description':
          'A nonsteroidal anti-inflammatory drug (NSAID) that reduces inflammation and pain caused by various conditions.',
      'alternatives': [
        {
          'name': 'Advil',
          'linktobuy':
              'https://www.walgreens.com/store/c/advil-pain-reliever/fever-reducer-tablets/ID=prod6041359-product'
        },
        {
          'name': 'Motrin',
          'linktobuy':
              'https://www.cvs.com/shop/motrin-ib-ibuprofen-tablets-prodid-1010138'
        },
        {
          'name': 'Brufen',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/brufen-400mg-tablet-15-s'
        },
        {
          'name': 'Nurofen',
          'linktobuy':
              'https://www.amazon.com/Nurofen-Ibuprofen-Pain-Relief-Tablets/dp/B07D7KX8K5'
        },
        {
          'name': 'IbuRelief',
          'linktobuy':
              'https://www.walmart.com/ip/Ibuprofen-200-mg-Pain-Reliever-100-Tablets/10324519'
        }
      ]
    },
    'Cetirizine': {
      'description':
          'An antihistamine used to relieve allergy symptoms like watery eyes, runny nose, itching, and hives.',
      'alternatives': [
        {
          'name': 'Zyrtec',
          'linktobuy':
              'https://www.walgreens.com/store/c/zyrtec-24-hour-allergy-relief-tablets/ID=prod6041360-product'
        },
        {
          'name': 'Alerid',
          'linktobuy': 'https://www.1mg.com/drugs/alerid-10mg-tablet-20507'
        },
        {
          'name': 'Cetriz',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/cetriz-10mg-tablet-10-s'
        },
        {
          'name': 'Allercet',
          'linktobuy':
              'https://www.apollopharmacy.in/medicine/allercet-10mg-tablet'
        },
        {
          'name': 'Cetzine',
          'linktobuy': 'https://www.amazon.in/Cetzine-Tablet-10s/dp/B07KX8J5K5'
        }
      ]
    },
    'Aspirin': {
      'description':
          'A salicylate used to relieve pain, reduce inflammation, and lower fever; also used as a blood thinner.',
      'alternatives': [
        {
          'name': 'Bayer Aspirin',
          'linktobuy':
              'https://www.walgreens.com/store/c/bayer-aspirin-regimen-low-dose/ID=prod6041361-product'
        },
        {
          'name': 'Ecotrin',
          'linktobuy':
              'https://www.cvs.com/shop/ecotrin-low-strength-aspirin-prodid-1010139'
        },
        {
          'name': 'Disprin',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/disprin-tablet-10-s'
        }
      ]
    },
    'Omeprazole': {
      'description':
          'A proton pump inhibitor (PPI) used to treat acid reflux, ulcers, and heartburn.',
      'alternatives': [
        {
          'name': 'Prilosec',
          'linktobuy':
              'https://www.walgreens.com/store/c/prilosec-otc-acid-reducer-tablets/ID=prod6041362-product'
        },
        {
          'name': 'Omez',
          'linktobuy': 'https://www.1mg.com/drugs/omez-20mg-capsule-20508'
        },
        {
          'name': 'Omeprazole (Generic)',
          'linktobuy':
              'https://www.amazon.com/Omeprazole-Delayed-Release-Tablets-20mg/dp/B07D7KX8K6'
        }
      ]
    },
    'Metformin': {
      'description':
          'An oral diabetes medicine that helps control blood sugar levels.',
      'alternatives': [
        {
          'name': 'Glucophage',
          'linktobuy':
              'https://www.walmart.com/ip/Glucophage-Metformin-500mg-Tablets/10324520'
        },
        {
          'name': 'Glycomet',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/glycomet-500mg-tablet-15-s'
        },
        {
          'name': 'Metformin (Generic)',
          'linktobuy':
              'https://www.cvs.com/shop/metformin-hcl-500-mg-tablets-prodid-1010140'
        }
      ]
    },
    'Loratadine': {
      'description':
          'An antihistamine used to treat allergies, including hay fever and hives.',
      'alternatives': [
        {
          'name': 'Claritin',
          'linktobuy':
              'https://www.walgreens.com/store/c/claritin-24-hour-allergy-relief-tablets/ID=prod6041363-product'
        },
        {
          'name': 'Alavert',
          'linktobuy':
              'https://www.amazon.com/Alavert-Allergy-Relief-Tablets-10mg/dp/B07D7KX8K7'
        },
        {
          'name': 'Lorfast',
          'linktobuy': 'https://www.1mg.com/drugs/lorfast-10mg-tablet-20509'
        }
      ]
    },
    'Amoxicillin': {
      'description':
          'An antibiotic used to treat bacterial infections such as pneumonia, bronchitis, and infections of the ear, nose, throat, skin, or urinary tract.',
      'alternatives': [
        {
          'name': 'Amoxil',
          'linktobuy':
              'https://www.walmart.com/ip/Amoxicillin-500mg-Capsules/10324521'
        },
        {
          'name': 'Moxatag',
          'linktobuy':
              'https://www.cvs.com/shop/amoxicillin-500-mg-capsules-prodid-1010141'
        },
        {
          'name': 'Himox',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/himox-500mg-capsule-10-s'
        }
      ]
    },
    'Simvastatin': {
      'description':
          'A statin used to lower cholesterol and triglycerides in the blood.',
      'alternatives': [
        {
          'name': 'Zocor',
          'linktobuy':
              'https://www.walgreens.com/store/c/zocor-simvastatin-tablets/ID=prod6041364-product'
        },
        {
          'name': 'Simvastol',
          'linktobuy': 'https://www.1mg.com/drugs/simvastol-20mg-tablet-20510'
        },
        {
          'name': 'Simvastatin (Generic)',
          'linktobuy':
              'https://www.amazon.com/Simvastatin-Tablets-20mg-30-Count/dp/B07D7KX8K8'
        }
      ]
    },
    'Levothyroxine': {
      'description':
          'A synthetic thyroid hormone used to treat hypothyroidism.',
      'alternatives': [
        {
          'name': 'Synthroid',
          'linktobuy':
              'https://www.walgreens.com/store/c/synthroid-levothyroxine-tablets/ID=prod6041365-product'
        },
        {
          'name': 'Levoxyl',
          'linktobuy':
              'https://www.cvs.com/shop/levothyroxine-sodium-50-mcg-tablets-prodid-1010142'
        },
        {
          'name': 'Thyronorm',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/thyronorm-50mcg-tablet-30-s'
        }
      ]
    },
    'Amlodipine': {
      'description':
          'A calcium channel blocker used to treat high blood pressure and chest pain (angina).',
      'alternatives': [
        {
          'name': 'Norvasc',
          'linktobuy':
              'https://www.walgreens.com/store/c/norvasc-amlodipine-besylate-tablets/ID=prod6041366-product'
        },
        {
          'name': 'Amlopres',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/amlopres-5mg-tablet-10-s'
        },
        {
          'name': 'Amlodac',
          'linktobuy': 'https://www.1mg.com/drugs/amlodac-5-tablet-20511'
        }
      ]
    },
    'Atorvastatin': {
      'description':
          'A statin used to lower cholesterol and reduce the risk of heart disease.',
      'alternatives': [
        {
          'name': 'Lipitor',
          'linktobuy':
              'https://www.walgreens.com/store/c/lipitor-atorvastatin-calcium-tablets/ID=prod6041367-product'
        },
        {
          'name': 'Atorva',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/atorva-10mg-tablet-10-s'
        },
        {
          'name': 'Storvas',
          'linktobuy': 'https://www.1mg.com/drugs/storvas-10-tablet-20512'
        }
      ]
    },
    'Lisinopril': {
      'description':
          'An ACE inhibitor used to treat high blood pressure and heart failure.',
      'alternatives': [
        {
          'name': 'Zestril',
          'linktobuy':
              'https://www.cvs.com/shop/lisinopril-10-mg-tablets-prodid-1010143'
        },
        {
          'name': 'Lisnop',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/lisnop-5mg-tablet-10-s'
        },
        {
          'name': 'Lisoril',
          'linktobuy': 'https://www.1mg.com/drugs/lisoril-5-tablet-20513'
        }
      ]
    },
    'Gabapentin': {
      'description': 'An anticonvulsant used to treat seizures and nerve pain.',
      'alternatives': [
        {
          'name': 'Neurontin',
          'linktobuy':
              'https://www.walgreens.com/store/c/neurontin-gabapentin-capsules/ID=prod6041368-product'
        },
        {
          'name': 'Gabantin',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/gabantin-300mg-capsule-10-s'
        },
        {
          'name': 'Gabapin',
          'linktobuy': 'https://www.1mg.com/drugs/gabapin-300-capsule-20514'
        }
      ]
    },
    'Albuterol': {
      'description':
          'A bronchodilator used to treat asthma and chronic obstructive pulmonary disease (COPD).',
      'alternatives': [
        {
          'name': 'Ventolin',
          'linktobuy':
              'https://www.walgreens.com/store/c/ventolin-hfa-albuterol-sulfate-inhaler/ID=prod6041369-product'
        },
        {
          'name': 'Asthalin',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/asthalin-100mcg-inhaler'
        },
        {
          'name': 'Salbutamol',
          'linktobuy':
              'https://www.amazon.com/Salbutamol-Inhaler-100mcg/dp/B08L9T8K6P'
        }
      ]
    },
    'Prednisone': {
      'description':
          'A corticosteroid used to reduce inflammation and treat autoimmune conditions.',
      'alternatives': [
        {
          'name': 'Deltasone',
          'linktobuy':
              'https://www.cvs.com/shop/prednisone-10-mg-tablets-prodid-1010144'
        },
        {
          'name': 'Wysolone',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/wysolone-10mg-tablet-10-s'
        },
        {
          'name': 'Prednisolone',
          'linktobuy':
              'https://www.amazon.com/Prednisolone-Tablets-5mg-100/dp/B07D7KX8K9'
        }
      ]
    },
    'Sertraline': {
      'description':
          'An SSRI antidepressant used to treat depression, anxiety, and OCD.',
      'alternatives': [
        {
          'name': 'Zoloft',
          'linktobuy':
              'https://www.walgreens.com/store/c/zoloft-sertraline-hcl-tablets/ID=prod6041370-product'
        },
        {
          'name': 'Sertima',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/sertima-50mg-tablet-10-s'
        },
        {
          'name': 'Daxid',
          'linktobuy': 'https://www.1mg.com/drugs/daxid-50mg-tablet-20515'
        }
      ]
    },
    'Montelukast': {
      'description':
          'A leukotriene inhibitor used to manage asthma and allergies.',
      'alternatives': [
        {
          'name': 'Singulair',
          'linktobuy':
              'https://www.walgreens.com/store/c/singulair-montelukast-sodium-tablets/ID=prod6041371-product'
        },
        {
          'name': 'Montair',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/montair-10mg-tablet-10-s'
        },
        {
          'name': 'Telekast',
          'linktobuy': 'https://www.1mg.com/drugs/telekast-10-tablet-20516'
        }
      ]
    },
    'Ciprofloxacin': {
      'description':
          'A fluoroquinolone antibiotic used to treat bacterial infections.',
      'alternatives': [
        {
          'name': 'Cipro',
          'linktobuy':
              'https://www.walgreens.com/store/c/cipro-ciprofloxacin-hcl-tablets/ID=prod6041372-product'
        },
        {
          'name': 'Ciplox',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/ciplox-500mg-tablet-10-s'
        },
        {
          'name': 'Cifran',
          'linktobuy': 'https://www.1mg.com/drugs/cifran-500-tablet-20517'
        }
      ]
    },
    'Losartan': {
      'description':
          'An ARB used to treat high blood pressure and protect the kidneys.',
      'alternatives': [
        {
          'name': 'Cozaar',
          'linktobuy':
              'https://www.walgreens.com/store/c/cozaar-losartan-potassium-tablets/ID=prod6041373-product'
        },
        {
          'name': 'Losar',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/losar-50mg-tablet-10-s'
        },
        {
          'name': 'Repace',
          'linktobuy': 'https://www.1mg.com/drugs/repace-50-tablet-20518'
        }
      ]
    },
    'Hydrochlorothiazide': {
      'description':
          'A diuretic used to treat high blood pressure and fluid retention.',
      'alternatives': [
        {
          'name': 'Microzide',
          'linktobuy':
              'https://www.cvs.com/shop/hydrochlorothiazide-25-mg-tablets-prodid-1010145'
        },
        {
          'name': 'Aquazide',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/aquazide-12-5mg-tablet-10-s'
        },
        {
          'name': 'Hydride',
          'linktobuy': 'https://www.1mg.com/drugs/hydride-25-tablet-20519'
        }
      ]
    },
    'Fluoxetine': {
      'description':
          'An SSRI antidepressant used to treat depression, OCD, and bulimia.',
      'alternatives': [
        {
          'name': 'Prozac',
          'linktobuy':
              'https://www.walgreens.com/store/c/prozac-fluoxetine-hcl-capsules/ID=prod6041374-product'
        },
        {
          'name': 'Fludac',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/fludac-20mg-capsule-10-s'
        },
        {
          'name': 'Flunil',
          'linktobuy': 'https://www.1mg.com/drugs/flunil-20-capsule-20520'
        }
      ]
    },
    'Metoprolol': {
      'description':
          'A beta-blocker used to treat high blood pressure and heart conditions.',
      'alternatives': [
        {
          'name': 'Lopressor',
          'linktobuy':
              'https://www.walgreens.com/store/c/lopressor-metoprolol-tartrate-tablets/ID=prod6041375-product'
        },
        {
          'name': 'Metolar',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/metolar-25mg-tablet-10-s'
        },
        {
          'name': 'Betaloc',
          'linktobuy': 'https://www.1mg.com/drugs/betaloc-25-tablet-20521'
        }
      ]
    },
    'Ranitidine': {
      'description':
          'An H2 blocker used to reduce stomach acid and treat ulcers (Note: recalled in some regions).',
      'alternatives': [
        {
          'name': 'Zantac',
          'linktobuy':
              'https://www.amazon.com/Zantac-Ranitidine-Tablets-150mg/dp/B07D7KX8KA'
        },
        {
          'name': 'Rantac',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/rantac-150mg-tablet-10-s'
        },
        {
          'name': 'Aciloc',
          'linktobuy': 'https://www.1mg.com/drugs/aciloc-150-tablet-20522'
        }
      ]
    },
    'Tramadol': {
      'description':
          'An opioid analgesic used to treat moderate to severe pain.',
      'alternatives': [
        {
          'name': 'Ultram',
          'linktobuy':
              'https://www.walgreens.com/store/c/ultram-tramadol-hcl-tablets/ID=prod6041376-product'
        },
        {
          'name': 'Tramazac',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/tramazac-50mg-capsule-10-s'
        },
        {
          'name': 'Tramasure',
          'linktobuy': 'https://www.1mg.com/drugs/tramasure-50-capsule-20523'
        }
      ]
    },
    'Clopidogrel': {
      'description':
          'An antiplatelet medication used to prevent heart attacks and strokes.',
      'alternatives': [
        {
          'name': 'Plavix',
          'linktobuy':
              'https://www.walgreens.com/store/c/plavix-clopidogrel-bisulfate-tablets/ID=prod6041377-product'
        },
        {
          'name': 'Clopilet',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/clopilet-75mg-tablet-10-s'
        },
        {
          'name': 'Ceruvin',
          'linktobuy': 'https://www.1mg.com/drugs/ceruvin-75-tablet-20524'
        }
      ]
    },
    'Diazepam': {
      'description':
          'A benzodiazepine used to treat anxiety, muscle spasms, and seizures.',
      'alternatives': [
        {
          'name': 'Valium',
          'linktobuy':
              'https://www.walgreens.com/store/c/valium-diazepam-tablets/ID=prod6041378-product'
        },
        {
          'name': 'Calmpose',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/calmpose-5mg-tablet-10-s'
        },
        {
          'name': 'Dizep',
          'linktobuy': 'https://www.1mg.com/drugs/dizep-5-tablet-20525'
        }
      ]
    },
    'Furosemide': {
      'description':
          'A loop diuretic used to treat fluid retention and high blood pressure.',
      'alternatives': [
        {
          'name': 'Lasix',
          'linktobuy':
              'https://www.walgreens.com/store/c/lasix-furosemide-tablets/ID=prod6041379-product'
        },
        {
          'name': 'Frusenex',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/frusenex-40mg-tablet-10-s'
        },
        {
          'name': 'Lasilactone',
          'linktobuy': 'https://www.1mg.com/drugs/lasilactone-50-tablet-20526'
        }
      ]
    },
    'Pantoprazole': {
      'description':
          'A proton pump inhibitor used to treat acid reflux and ulcers.',
      'alternatives': [
        {
          'name': 'Protonix',
          'linktobuy':
              'https://www.walgreens.com/store/c/protonix-pantoprazole-sodium-tablets/ID=prod6041380-product'
        },
        {
          'name': 'Pantocid',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/pantocid-40mg-tablet-10-s'
        },
        {
          'name': 'Pan',
          'linktobuy': 'https://www.1mg.com/drugs/pan-40-tablet-20527'
        }
      ]
    },
    'Tadalafil': {
      'description':
          'A PDE5 inhibitor used to treat erectile dysfunction and benign prostatic hyperplasia.',
      'alternatives': [
        {
          'name': 'Cialis',
          'linktobuy':
              'https://www.walgreens.com/store/c/cialis-tadalafil-tablets/ID=prod6041381-product'
        },
        {
          'name': 'Tadacip',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/tadacip-20mg-tablet-4-s'
        },
        {
          'name': 'Megalis',
          'linktobuy': 'https://www.1mg.com/drugs/megalis-20-tablet-20528'
        }
      ]
    },
    'Azithromycin': {
      'description':
          'A macrolide antibiotic used to treat bacterial infections like pneumonia and STDs.',
      'alternatives': [
        {
          'name': 'Zithromax',
          'linktobuy':
              'https://www.walgreens.com/store/c/zithromax-azithromycin-tablets/ID=prod6041382-product'
        },
        {
          'name': 'Azithral',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/azithral-500mg-tablet-5-s'
        },
        {
          'name': 'Azee',
          'linktobuy': 'https://www.1mg.com/drugs/azee-500-tablet-20529'
        }
      ]
    },
    'Escitalopram': {
      'description':
          'An SSRI antidepressant used to treat depression and generalized anxiety disorder.',
      'alternatives': [
        {
          'name': 'Lexapro',
          'linktobuy':
              'https://www.walgreens.com/store/c/lexapro-escitalopram-oxalate-tablets/ID=prod6041383-product'
        },
        {
          'name': 'Cipralex',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/cipralex-10mg-tablet-10-s'
        },
        {
          'name': 'Nexito',
          'linktobuy': 'https://www.1mg.com/drugs/nexito-10-tablet-20530'
        }
      ]
    },
    'Levofloxacin': {
      'description':
          'A fluoroquinolone antibiotic used to treat bacterial infections.',
      'alternatives': [
        {
          'name': 'Levaquin',
          'linktobuy':
              'https://www.walgreens.com/store/c/levaquin-levofloxacin-tablets/ID=prod6041384-product'
        },
        {
          'name': 'Levoday',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/levoday-500mg-tablet-5-s'
        },
        {
          'name': 'Loxof',
          'linktobuy': 'https://www.1mg.com/drugs/loxof-500-tablet-20531'
        }
      ]
    },
    'Venlafaxine': {
      'description':
          'An SNRI antidepressant used to treat depression and anxiety disorders.',
      'alternatives': [
        {
          'name': 'Effexor',
          'linktobuy':
              'https://www.walgreens.com/store/c/effexor-xr-venlafaxine-hcl-capsules/ID=prod6041385-product'
        },
        {
          'name': 'Veniz',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/veniz-xr-75mg-capsule-10-s'
        },
        {
          'name': 'Venlift',
          'linktobuy': 'https://www.1mg.com/drugs/venlift-od-75-capsule-20532'
        }
      ]
    },
    'Sildenafil': {
      'description': 'A PDE5 inhibitor used to treat erectile dysfunction.',
      'alternatives': [
        {
          'name': 'Viagra',
          'linktobuy':
              'https://www.walgreens.com/store/c/viagra-sildenafil-citrate-tablets/ID=prod6041386-product'
        },
        {
          'name': 'Silagra',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/silagra-100mg-tablet-4-s'
        },
        {
          'name': 'Caverta',
          'linktobuy': 'https://www.1mg.com/drugs/caverta-100-tablet-20533'
        }
      ]
    },
    'Carvedilol': {
      'description':
          'A beta-blocker used to treat high blood pressure and heart failure.',
      'alternatives': [
        {
          'name': 'Coreg',
          'linktobuy':
              'https://www.walgreens.com/store/c/coreg-carvedilol-tablets/ID=prod6041387-product'
        },
        {
          'name': 'Carloc',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/carloc-6-25mg-tablet-10-s'
        },
        {
          'name': 'Cardivas',
          'linktobuy': 'https://www.1mg.com/drugs/cardivas-6-25-tablet-20534'
        }
      ]
    },
    'Risperidone': {
      'description':
          'An atypical antipsychotic used to treat schizophrenia and bipolar disorder.',
      'alternatives': [
        {
          'name': 'Risperdal',
          'linktobuy':
              'https://www.walgreens.com/store/c/risperdal-risperidone-tablets/ID=prod6041388-product'
        },
        {
          'name': 'Risdone',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/risdone-2mg-tablet-10-s'
        },
        {
          'name': 'Sizodon',
          'linktobuy': 'https://www.1mg.com/drugs/sizodon-2-tablet-20535'
        }
      ]
    },
    'Budesonide': {
      'description':
          'A corticosteroid used to treat asthma and inflammatory bowel disease.',
      'alternatives': [
        {
          'name': 'Pulmicort',
          'linktobuy':
              'https://www.walgreens.com/store/c/pulmicort-budesonide-inhalation-suspension/ID=prod6041389-product'
        },
        {
          'name': 'Budecort',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/budecort-100mcg-inhaler'
        },
        {
          'name': 'Budenase',
          'linktobuy': 'https://www.1mg.com/drugs/budenase-aq-nasal-spray-20536'
        }
      ]
    },
    'Duloxetine': {
      'description':
          'An SNRI used to treat depression, anxiety, and chronic pain.',
      'alternatives': [
        {
          'name': 'Cymbalta',
          'linktobuy':
              'https://www.walgreens.com/store/c/cymbalta-duloxetine-hcl-capsules/ID=prod6041390-product'
        },
        {
          'name': 'Duzela',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/duzela-30mg-capsule-10-s'
        },
        {
          'name': 'Dulane',
          'linktobuy': 'https://www.1mg.com/drugs/dulane-30-capsule-20537'
        }
      ]
    },
    'Warfarin': {
      'description': 'An anticoagulant used to prevent blood clots.',
      'alternatives': [
        {
          'name': 'Coumadin',
          'linktobuy':
              'https://www.walgreens.com/store/c/coumadin-warfarin-sodium-tablets/ID=prod6041391-product'
        },
        {
          'name': 'Warf',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/warf-5mg-tablet-10-s'
        },
        {
          'name': 'Uniwarfin',
          'linktobuy': 'https://www.1mg.com/drugs/uniwarfin-5-tablet-20538'
        }
      ]
    },
    'Allopurinol': {
      'description':
          'A xanthine oxidase inhibitor used to treat gout and kidney stones by reducing uric acid.',
      'alternatives': [
        {
          'name': 'Zyloprim',
          'linktobuy':
              'https://www.walgreens.com/store/c/zyloprim-allopurinol-tablets/ID=prod6041392-product'
        },
        {
          'name': 'Zyloric',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/zyloric-100mg-tablet-10-s'
        },
        {
          'name': 'Aloric',
          'linktobuy': 'https://www.1mg.com/drugs/aloric-100-tablet-20539'
        }
      ]
    },
    'Bisoprolol': {
      'description':
          'A beta-blocker used to treat high blood pressure and heart failure.',
      'alternatives': [
        {
          'name': 'Zebeta',
          'linktobuy':
              'https://www.walgreens.com/store/c/zebeta-bisoprolol-fumarate-tablets/ID=prod6041393-product'
        },
        {
          'name': 'Concor',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/concor-5mg-tablet-10-s'
        },
        {
          'name': 'Bisoheart',
          'linktobuy': 'https://www.1mg.com/drugs/bisoheart-5-tablet-20540'
        }
      ]
    },
    'Clonazepam': {
      'description':
          'A benzodiazepine used to treat seizures, panic disorder, and anxiety.',
      'alternatives': [
        {
          'name': 'Klonopin',
          'linktobuy':
              'https://www.walgreens.com/store/c/klonopin-clonazepam-tablets/ID=prod6041394-product'
        },
        {
          'name': 'Lonazep',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/lonazep-0-5mg-tablet-10-s'
        },
        {
          'name': 'Clonotril',
          'linktobuy': 'https://www.1mg.com/drugs/clonotril-0-5-tablet-20541'
        }
      ]
    },
    'Doxycycline': {
      'description':
          'A tetracycline antibiotic used to treat bacterial infections, including acne and respiratory infections.',
      'alternatives': [
        {
          'name': 'Vibramycin',
          'linktobuy':
              'https://www.walgreens.com/store/c/vibramycin-doxycycline-hyclate-capsules/ID=prod6041395-product'
        },
        {
          'name': 'Doxy-1',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/doxy-1-100mg-capsule-10-s'
        },
        {
          'name': 'Doxicip',
          'linktobuy': 'https://www.1mg.com/drugs/doxicip-100-capsule-20542'
        }
      ]
    },
    'Esomeprazole': {
      'description':
          'A proton pump inhibitor used to treat GERD and stomach ulcers.',
      'alternatives': [
        {
          'name': 'Nexium',
          'linktobuy':
              'https://www.walgreens.com/store/c/nexium-esomeprazole-magnesium-capsules/ID=prod6041396-product'
        },
        {
          'name': 'Nexpro',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/nexpro-40mg-tablet-10-s'
        },
        {
          'name': 'Esoz',
          'linktobuy': 'https://www.1mg.com/drugs/esoz-40-tablet-20543'
        }
      ]
    },
    'Finasteride': {
      'description':
          'A 5-alpha reductase inhibitor used to treat benign prostatic hyperplasia and hair loss.',
      'alternatives': [
        {
          'name': 'Propecia',
          'linktobuy':
              'https://www.walgreens.com/store/c/propecia-finasteride-tablets/ID=prod6041397-product'
        },
        {
          'name': 'Finpecia',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/finpecia-1mg-tablet-10-s'
        },
        {
          'name': 'Fincar',
          'linktobuy': 'https://www.1mg.com/drugs/fincar-5-tablet-20544'
        }
      ]
    },
    'Glimepiride': {
      'description':
          'A sulfonylurea used to treat type 2 diabetes by lowering blood sugar.',
      'alternatives': [
        {
          'name': 'Amaryl',
          'linktobuy':
              'https://www.walgreens.com/store/c/amaryl-glimepiride-tablets/ID=prod6041398-product'
        },
        {
          'name': 'Glimestar',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/glimestar-2mg-tablet-10-s'
        },
        {
          'name': 'Glypride',
          'linktobuy': 'https://www.1mg.com/drugs/glypride-2-tablet-20545'
        }
      ]
    },
    'Hydroxyzine': {
      'description':
          'An antihistamine used to treat anxiety, itching, and allergies.',
      'alternatives': [
        {
          'name': 'Vistaril',
          'linktobuy':
              'https://www.walgreens.com/store/c/vistaril-hydroxyzine-pamoate-capsules/ID=prod6041399-product'
        },
        {
          'name': 'Atarax',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/atarax-25mg-tablet-10-s'
        },
        {
          'name': 'Hydrox',
          'linktobuy': 'https://www.1mg.com/drugs/hydrox-25-tablet-20546'
        }
      ]
    },
    'Isosorbide Mononitrate': {
      'description':
          'A nitrate used to prevent chest pain (angina) in patients with heart conditions.',
      'alternatives': [
        {
          'name': 'Imdur',
          'linktobuy':
              'https://www.walgreens.com/store/c/imdur-isosorbide-mononitrate-tablets/ID=prod6041400-product'
        },
        {
          'name': 'Monotrate',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/monotrate-20mg-tablet-10-s'
        },
        {
          'name': 'Ismo',
          'linktobuy': 'https://www.1mg.com/drugs/ismo-20-tablet-20547'
        }
      ]
    },
    'Lansoprazole': {
      'description':
          'A proton pump inhibitor used to treat acid reflux and ulcers.',
      'alternatives': [
        {
          'name': 'Prevacid',
          'linktobuy':
              'https://www.walgreens.com/store/c/prevacid-lansoprazole-capsules/ID=prod6041401-product'
        },
        {
          'name': 'Lan',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/lan-30mg-capsule-10-s'
        },
        {
          'name': 'Lanzol',
          'linktobuy': 'https://www.1mg.com/drugs/lanzol-30-capsule-20548'
        }
      ]
    },
    'Meloxicam': {
      'description':
          'An NSAID used to relieve pain and inflammation in arthritis.',
      'alternatives': [
        {
          'name': 'Mobic',
          'linktobuy':
              'https://www.walgreens.com/store/c/mobic-meloxicam-tablets/ID=prod6041402-product'
        },
        {
          'name': 'Muvera',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/muvera-15mg-tablet-10-s'
        },
        {
          'name': 'Melodol',
          'linktobuy': 'https://www.1mg.com/drugs/melodol-15-tablet-20549'
        }
      ]
    },
    'Naproxen': {
      'description':
          'An NSAID used to relieve pain, inflammation, and stiffness.',
      'alternatives': [
        {
          'name': 'Aleve',
          'linktobuy':
              'https://www.walgreens.com/store/c/aleve-naproxen-sodium-tablets/ID=prod6041403-product'
        },
        {
          'name': 'Naprosyn',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/naprosyn-500mg-tablet-10-s'
        },
        {
          'name': 'Naxdom',
          'linktobuy': 'https://www.1mg.com/drugs/naxdom-500-tablet-20550'
        }
      ]
    },
    'Ondansetron': {
      'description':
          'An antiemetic used to prevent nausea and vomiting caused by chemotherapy or surgery.',
      'alternatives': [
        {
          'name': 'Zofran',
          'linktobuy':
              'https://www.walgreens.com/store/c/zofran-ondansetron-hcl-tablets/ID=prod6041404-product'
        },
        {
          'name': 'Emeset',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/emeset-4mg-tablet-10-s'
        },
        {
          'name': 'Vomikind',
          'linktobuy': 'https://www.1mg.com/drugs/vomikind-4-tablet-20551'
        }
      ]
    },
    'Paroxetine': {
      'description':
          'An SSRI antidepressant used to treat depression, anxiety, and PTSD.',
      'alternatives': [
        {
          'name': 'Paxil',
          'linktobuy':
              'https://www.walgreens.com/store/c/paxil-paroxetine-hcl-tablets/ID=prod6041405-product'
        },
        {
          'name': 'Pari',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/pari-20mg-tablet-10-s'
        },
        {
          'name': 'Xet',
          'linktobuy': 'https://www.1mg.com/drugs/xet-20-tablet-20552'
        }
      ]
    },
    'Quetiapine': {
      'description':
          'An atypical antipsychotic used to treat schizophrenia, bipolar disorder, and depression.',
      'alternatives': [
        {
          'name': 'Seroquel',
          'linktobuy':
              'https://www.walgreens.com/store/c/seroquel-quetiapine-fumarate-tablets/ID=prod6041406-product'
        },
        {
          'name': 'Qutipin',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/qutipin-25mg-tablet-10-s'
        },
        {
          'name': 'Seroquin',
          'linktobuy': 'https://www.1mg.com/drugs/seroquin-25-tablet-20553'
        }
      ]
    },
    'Rosuvastatin': {
      'description':
          'A statin used to lower cholesterol and reduce cardiovascular risk.',
      'alternatives': [
        {
          'name': 'Crestor',
          'linktobuy':
              'https://www.walgreens.com/store/c/crestor-rosuvastatin-calcium-tablets/ID=prod6041407-product'
        },
        {
          'name': 'Rosuvas',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/rosuvas-10mg-tablet-10-s'
        },
        {
          'name': 'Rozavel',
          'linktobuy': 'https://www.1mg.com/drugs/rozavel-10-tablet-20554'
        }
      ]
    },
    'Spironolactone': {
      'description':
          'A diuretic used to treat high blood pressure, heart failure, and edema.',
      'alternatives': [
        {
          'name': 'Aldactone',
          'linktobuy':
              'https://www.walgreens.com/store/c/aldactone-spironolactone-tablets/ID=prod6041408-product'
        },
        {
          'name': 'Spiractin',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/spiractin-25mg-tablet-10-s'
        },
        {
          'name': 'Lasilactone',
          'linktobuy': 'https://www.1mg.com/drugs/lasilactone-50-tablet-20555'
        }
      ]
    },
    'Tamsulosin': {
      'description':
          'An alpha-blocker used to treat benign prostatic hyperplasia (BPH).',
      'alternatives': [
        {
          'name': 'Flomax',
          'linktobuy':
              'https://www.walgreens.com/store/c/flomax-tamsulosin-hcl-capsules/ID=prod6041409-product'
        },
        {
          'name': 'Urimax',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/urimax-0-4mg-capsule-10-s'
        },
        {
          'name': 'Tamdura',
          'linktobuy': 'https://www.1mg.com/drugs/tamdura-capsule-20556'
        }
      ]
    },
    'Topiramate': {
      'description':
          'An anticonvulsant used to treat epilepsy and prevent migraines.',
      'alternatives': [
        {
          'name': 'Topamax',
          'linktobuy':
              'https://www.walgreens.com/store/c/topamax-topiramate-tablets/ID=prod6041410-product'
        },
        {
          'name': 'Topamac',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/topamac-25mg-tablet-10-s'
        },
        {
          'name': 'Topirate',
          'linktobuy': 'https://www.1mg.com/drugs/topirate-25-tablet-20557'
        }
      ]
    },
    'Valproate': {
      'description':
          'An anticonvulsant used to treat epilepsy, bipolar disorder, and migraines.',
      'alternatives': [
        {
          'name': 'Depakote',
          'linktobuy':
              'https://www.walgreens.com/store/c/depakote-valproic-acid-tablets/ID=prod6041411-product'
        },
        {
          'name': 'Valparin',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/valparin-200mg-tablet-10-s'
        },
        {
          'name': 'Encorate',
          'linktobuy': 'https://www.1mg.com/drugs/encorate-200-tablet-20558'
        }
      ]
    },
    'Zolpidem': {
      'description': 'A sedative-hypnotic used to treat insomnia.',
      'alternatives': [
        {
          'name': 'Ambien',
          'linktobuy':
              'https://www.walgreens.com/store/c/ambien-zolpidem-tartrate-tablets/ID=prod6041412-product'
        },
        {
          'name': 'Zolfresh',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/zolfresh-10mg-tablet-10-s'
        },
        {
          'name': 'Nitrest',
          'linktobuy': 'https://www.1mg.com/drugs/nitrest-10-tablet-20559'
        }
      ]
    },
    'Atenolol': {
      'description':
          'A beta-blocker used to treat high blood pressure and chest pain.',
      'alternatives': [
        {
          'name': 'Tenormin',
          'linktobuy':
              'https://www.walgreens.com/store/c/tenormin-atenolol-tablets/ID=prod6041413-product'
        },
        {
          'name': 'Aten',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/aten-50mg-tablet-14-s'
        },
        {
          'name': 'Betacard',
          'linktobuy': 'https://www.1mg.com/drugs/betacard-50-tablet-20560'
        }
      ]
    },
    'Bupropion': {
      'description':
          'An antidepressant used to treat depression and aid smoking cessation.',
      'alternatives': [
        {
          'name': 'Wellbutrin',
          'linktobuy':
              'https://www.walgreens.com/store/c/wellbutrin-bupropion-hcl-tablets/ID=prod6041414-product'
        },
        {
          'name': 'Bupron',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/bupron-sr-150mg-tablet-10-s'
        },
        {
          'name': 'Zyban',
          'linktobuy': 'https://www.1mg.com/drugs/zyban-150-tablet-20561'
        }
      ]
    },
    'Citalopram': {
      'description': 'An SSRI antidepressant used to treat depression.',
      'alternatives': [
        {
          'name': 'Celexa',
          'linktobuy':
              'https://www.walgreens.com/store/c/celexa-citalopram-hbr-tablets/ID=prod6041415-product'
        },
        {
          'name': 'Citopam',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/citopam-20mg-tablet-10-s'
        },
        {
          'name': 'Cipam',
          'linktobuy': 'https://www.1mg.com/drugs/cipam-20-tablet-20562'
        }
      ]
    },
    'Clarithromycin': {
      'description':
          'A macrolide antibiotic used to treat bacterial infections.',
      'alternatives': [
        {
          'name': 'Biaxin',
          'linktobuy':
              'https://www.walgreens.com/store/c/biaxin-clarithromycin-tablets/ID=prod6041416-product'
        },
        {
          'name': 'Claribid',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/claribid-500mg-tablet-10-s'
        },
        {
          'name': 'Clariwin',
          'linktobuy': 'https://www.1mg.com/drugs/clariwin-500-tablet-20563'
        }
      ]
    },
    'Diclofenac': {
      'description': 'An NSAID used to relieve pain and inflammation.',
      'alternatives': [
        {
          'name': 'Voltaren',
          'linktobuy':
              'https://www.walgreens.com/store/c/voltaren-diclofenac-sodium-tablets/ID=prod6041417-product'
        },
        {
          'name': 'Voveran',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/voveran-50mg-tablet-10-s'
        },
        {
          'name': 'Dynapar',
          'linktobuy': 'https://www.1mg.com/drugs/dynapar-tablet-20564'
        }
      ]
    },
    'Ezetimibe': {
      'description':
          'A cholesterol absorption inhibitor used to lower cholesterol levels.',
      'alternatives': [
        {
          'name': 'Zetia',
          'linktobuy':
              'https://www.walgreens.com/store/c/zetia-ezetimibe-tablets/ID=prod6041418-product'
        },
        {
          'name': 'Ezedoc',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/ezedoc-10mg-tablet-10-s'
        },
        {
          'name': 'Ezetor',
          'linktobuy': 'https://www.1mg.com/drugs/ezetor-10-tablet-20565'
        }
      ]
    },
    'Famotidine': {
      'description':
          'An H2 blocker used to reduce stomach acid and treat heartburn.',
      'alternatives': [
        {
          'name': 'Pepcid',
          'linktobuy':
              'https://www.walgreens.com/store/c/pepcid-famotidine-tablets/ID=prod6041419-product'
        },
        {
          'name': 'Topcid',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/topcid-20mg-tablet-10-s'
        },
        {
          'name': 'Famocid',
          'linktobuy': 'https://www.1mg.com/drugs/famocid-20-tablet-20566'
        }
      ]
    },
    'Gemfibrozil': {
      'description': 'A fibrate used to lower triglycerides and cholesterol.',
      'alternatives': [
        {
          'name': 'Lopid',
          'linktobuy':
              'https://www.walgreens.com/store/c/lopid-gemfibrozil-tablets/ID=prod6041420-product'
        },
        {
          'name': 'Gempar',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/gempar-300mg-capsule-10-s'
        },
        {
          'name': 'Lipigem',
          'linktobuy': 'https://www.1mg.com/drugs/lipigem-300-capsule-20567'
        }
      ]
    },
    'Hydralazine': {
      'description': 'A vasodilator used to treat high blood pressure.',
      'alternatives': [
        {
          'name': 'Apresoline',
          'linktobuy':
              'https://www.walgreens.com/store/c/apresoline-hydralazine-hcl-tablets/ID=prod6041421-product'
        },
        {
          'name': 'Hydrazide',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/hydrazide-25mg-tablet-10-s'
        },
        {
          'name': 'Hydral',
          'linktobuy': 'https://www.1mg.com/drugs/hydral-25-tablet-20568'
        }
      ]
    },
    'Lamotrigine': {
      'description':
          'An anticonvulsant used to treat epilepsy and bipolar disorder.',
      'alternatives': [
        {
          'name': 'Lamictal',
          'linktobuy':
              'https://www.walgreens.com/store/c/lamictal-lamotrigine-tablets/ID=prod6041422-product'
        },
        {
          'name': 'Lamez',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/lamez-50mg-tablet-10-s'
        },
        {
          'name': 'Lametec',
          'linktobuy': 'https://www.1mg.com/drugs/lametec-50-tablet-20569'
        }
      ]
    },
    'Methotrexate': {
      'description':
          'A chemotherapy drug and immunosuppressant used to treat cancer and autoimmune diseases.',
      'alternatives': [
        {
          'name': 'Trexall',
          'linktobuy':
              'https://www.walgreens.com/store/c/trexall-methotrexate-tablets/ID=prod6041423-product'
        },
        {
          'name': 'Methorex',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/methorex-2-5mg-tablet-10-s'
        },
        {
          'name': 'Folitrax',
          'linktobuy': 'https://www.1mg.com/drugs/folitrax-10-tablet-20570'
        }
      ]
    },
    'Nifedipine': {
      'description':
          'A calcium channel blocker used to treat high blood pressure and chest pain.',
      'alternatives': [
        {
          'name': 'Procardia',
          'linktobuy':
              'https://www.walgreens.com/store/c/procardia-nifedipine-capsules/ID=prod6041424-product'
        },
        {
          'name': 'Nicardia',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/nicardia-10mg-capsule-10-s'
        },
        {
          'name': 'Nifedine',
          'linktobuy': 'https://www.1mg.com/drugs/nifedine-10-capsule-20571'
        }
      ]
    },
    'Olanzapine': {
      'description':
          'An atypical antipsychotic used to treat schizophrenia and bipolar disorder.',
      'alternatives': [
        {
          'name': 'Zyprexa',
          'linktobuy':
              'https://www.walgreens.com/store/c/zyprexa-olanzapine-tablets/ID=prod6041425-product'
        },
        {
          'name': 'Oleanz',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/oleanz-5mg-tablet-10-s'
        },
        {
          'name': 'Oliza',
          'linktobuy': 'https://www.1mg.com/drugs/oliza-5-tablet-20572'
        }
      ]
    },
    'Pravastatin': {
      'description':
          'A statin used to lower cholesterol and prevent cardiovascular disease.',
      'alternatives': [
        {
          'name': 'Pravachol',
          'linktobuy':
              'https://www.walgreens.com/store/c/pravachol-pravastatin-sodium-tablets/ID=prod6041426-product'
        },
        {
          'name': 'Pravator',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/pravator-10mg-tablet-10-s'
        },
        {
          'name': 'Prastatin',
          'linktobuy': 'https://www.1mg.com/drugs/prastatin-10-tablet-20573'
        }
      ]
    },
    'Pregabalin': {
      'description':
          'An anticonvulsant used to treat nerve pain, fibromyalgia, and seizures.',
      'alternatives': [
        {
          'name': 'Lyrica',
          'linktobuy':
              'https://www.walgreens.com/store/c/lyrica-pregabalin-capsules/ID=prod6041427-product'
        },
        {
          'name': 'Pregaba',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/pregaba-75mg-capsule-10-s'
        },
        {
          'name': 'Pregeb',
          'linktobuy': 'https://www.1mg.com/drugs/pregeb-75-capsule-20574'
        }
      ]
    },
    'Propranolol': {
      'description':
          'A beta-blocker used to treat high blood pressure, anxiety, and migraines.',
      'alternatives': [
        {
          'name': 'Inderal',
          'linktobuy':
              'https://www.walgreens.com/store/c/inderal-propranolol-hcl-tablets/ID=prod6041428-product'
        },
        {
          'name': 'Ciplar',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/ciplar-10mg-tablet-10-s'
        },
        {
          'name': 'Betacap',
          'linktobuy': 'https://www.1mg.com/drugs/betacap-tr-40-capsule-20575'
        }
      ]
    },
    'Rabeprazole': {
      'description': 'A proton pump inhibitor used to treat GERD and ulcers.',
      'alternatives': [
        {
          'name': 'Aciphex',
          'linktobuy':
              'https://www.walgreens.com/store/c/aciphex-rabeprazole-sodium-tablets/ID=prod6041429-product'
        },
        {
          'name': 'Razo',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/razo-20mg-tablet-10-s'
        },
        {
          'name': 'Rabium',
          'linktobuy': 'https://www.1mg.com/drugs/rabium-20-tablet-20576'
        }
      ]
    },
    'Sulfasalazine': {
      'description':
          'An anti-inflammatory drug used to treat rheumatoid arthritis and ulcerative colitis.',
      'alternatives': [
        {
          'name': 'Azulfidine',
          'linktobuy':
              'https://www.walgreens.com/store/c/azulfidine-sulfasalazine-tablets/ID=prod6041430-product'
        },
        {
          'name': 'Saaz',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/saaz-500mg-tablet-10-s'
        },
        {
          'name': 'Salazopyrin',
          'linktobuy': 'https://www.1mg.com/drugs/salazopyrin-500-tablet-20577'
        }
      ]
    },
    'Terbinafine': {
      'description':
          'An antifungal used to treat fungal infections of the skin and nails.',
      'alternatives': [
        {
          'name': 'Lamisil',
          'linktobuy':
              'https://www.walgreens.com/store/c/lamisil-terbinafine-hcl-tablets/ID=prod6041431-product'
        },
        {
          'name': 'Terbiforce',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/terbiforce-250mg-tablet-7-s'
        },
        {
          'name': 'Sebifin',
          'linktobuy': 'https://www.1mg.com/drugs/sebifin-250-tablet-20578'
        }
      ]
    },
    'Tizanidine': {
      'description': 'A muscle relaxant used to treat spasticity.',
      'alternatives': [
        {
          'name': 'Zanaflex',
          'linktobuy':
              'https://www.walgreens.com/store/c/zanaflex-tizanidine-hcl-tablets/ID=prod6041432-product'
        },
        {
          'name': 'Tizpa',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/tizpa-2mg-tablet-10-s'
        },
        {
          'name': 'Tizan',
          'linktobuy': 'https://www.1mg.com/drugs/tizan-2-tablet-20579'
        }
      ]
    },
    'Vardenafil': {
      'description': 'A PDE5 inhibitor used to treat erectile dysfunction.',
      'alternatives': [
        {
          'name': 'Levitra',
          'linktobuy':
              'https://www.walgreens.com/store/c/levitra-vardenafil-hcl-tablets/ID=prod6041433-product'
        },
        {
          'name': 'Vilitra',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/vilitra-20mg-tablet-10-s'
        },
        {
          'name': 'Vardegra',
          'linktobuy': 'https://www.1mg.com/drugs/vardegra-20-tablet-20580'
        }
      ]
    },
    'Verapamil': {
      'description':
          'A calcium channel blocker used to treat high blood pressure and arrhythmias.',
      'alternatives': [
        {
          'name': 'Calan',
          'linktobuy':
              'https://www.walgreens.com/store/c/calan-verapamil-hcl-tablets/ID=prod6041434-product'
        },
        {
          'name': 'Vpl',
          'linktobuy':
              'https://www.netmeds.com/prescriptions/vpl-40mg-tablet-10-s'
        },
        {
          'name': 'Veramil',
          'linktobuy': 'https://www.1mg.com/drugs/veramil-40-tablet-20581'
        }
      ]
    }
  };

  // Method to add a new generic medicine
  static void addGenericMedicine(String genericName, String description,
      List<Map<String, dynamic>> alternatives) {
    genericMedicines[genericName] = {
      'description': description,
      'alternatives': alternatives,
    };
  }

  // Method to add a new alternative to an existing generic medicine
  static void addAlternative(
      String genericName, String name, String linkToBuy) {
    if (genericMedicines.containsKey(genericName)) {
      genericMedicines[genericName]!['alternatives']
          .add({'name': name, 'linktobuy': linkToBuy});
    }
  }

  // Method to check if a medicine exists in the database
  static bool medicineExists(String medicineName) {
    final lowercaseName = medicineName.toLowerCase();

    for (final entry in genericMedicines.entries) {
      final alternatives =
          entry.value['alternatives'] as List<Map<String, dynamic>>;

      for (final alternative in alternatives) {
        if (alternative['name'].toString().toLowerCase() == lowercaseName) {
          return true;
        }
      }
    }

    return false;
  }

  // Method to get the generic name for a specific medicine
  static String? getGenericName(String medicineName) {
    final lowercaseName = medicineName.toLowerCase();

    for (final entry in genericMedicines.entries) {
      final genericName = entry.key;
      final alternatives =
          entry.value['alternatives'] as List<Map<String, dynamic>>;

      for (final alternative in alternatives) {
        if (alternative['name'].toString().toLowerCase() == lowercaseName) {
          return genericName;
        }
      }
    }

    return null;
  }
}
